import os
import sys
import math
import logging
import argparse
from typing import List, Dict, Any
from dotenv import load_dotenv
from pymongo import MongoClient, GEOSPHERE
from pymongo.errors import BulkWriteError

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv(os.path.join(os.path.dirname(__file__), '../.env'))

def get_db_collection():
    uri = os.getenv('MONGODB_URI')
    if not uri:
        logger.error("MONGODB_URI not found in environment variables.")
        sys.exit(1)
    
    try:
        client = MongoClient(uri)
        db = client.get_database('astr')
        collection = db.get_collection('light_pollution')
        return collection
    except Exception as e:
        logger.error(f"Failed to connect to MongoDB: {e}")
        sys.exit(1)

def radiance_to_mpsas(radiance: float) -> float:
    """
    Convert Black Marble Radiance (Watts/cm^2/sr) to MPSAS (Magnitudes Per Square Arcsecond).
    Formula: MPSAS = 12.589 - 1.086 * ln(radiance)
    
    Note: This is an approximation. Radiance is usually in nW/cm^2/sr in some products, 
    but VNP46A2 is often in nW/cm^2/sr. 
    If radiance is <= 0, we assume maximum darkness (e.g., 22.0).
    """
    if radiance <= 0:
        return 22.0
    
    try:
        # Assuming radiance is in nW/cm^2/sr. 
        # If the value is extremely small, log will be negative large number.
        mpsas = 12.589 - 1.086 * math.log(radiance)
        return max(16.0, min(22.0, mpsas)) # Clamp between 16 (bright city) and 22 (dark sky)
    except ValueError:
        return 22.0

def get_bortle_class(mpsas: float) -> int:
    """
    Map MPSAS to Bortle Class (1-9).
    """
    if mpsas >= 21.99: return 1
    if mpsas >= 21.89: return 2
    if mpsas >= 21.69: return 3
    if mpsas >= 20.49: return 4
    if mpsas >= 19.50: return 5
    if mpsas >= 18.94: return 6
    if mpsas >= 18.38: return 7
    if mpsas >= 17.80: return 8
    return 9

def parse_tile_id(file_path: str):
    """
    Extract tile horizontal (h) and vertical (v) indices from VNP46A2 filename.
    Example: VNP46A2.A2024001.h08v05.001.hdf -> (8, 5)
    Returns: (h_tile, v_tile) or (None, None) if parsing fails
    """
    import re
    match = re.search(r'h(\d{2})v(\d{2})', file_path)
    if match:
        return int(match.group(1)), int(match.group(2))
    return None, None

def tile_to_bounds(h_tile: int, v_tile: int):
    """
    Convert VNP46A2 tile indices to geographic bounds (lat/lon).
    VNP46A2 uses MODIS Sinusoidal projection with 10° tiles.

    Reference: https://modis-land.gsfc.nasa.gov/MODLAND_grid.html
    - 36 horizontal tiles (h00-h35): each 10° wide in sinusoidal projection
    - 18 vertical tiles (v00-v17): each 10° tall
    - Origin at upper-left corner

    Returns: (lat_min, lat_max, lon_min, lon_max)
    """
    # Vertical tiles: v00 is northernmost (90N), v17 is southernmost (approx -90N)
    # Each tile is ~10 degrees tall
    lat_max = 90.0 - (v_tile * 10.0)
    lat_min = lat_max - 10.0

    # Horizontal tiles: h00 starts at -180 (westernmost)
    # Each tile is 10 degrees wide at equator (varies with sinusoidal projection)
    lon_min = -180.0 + (h_tile * 10.0)
    lon_max = lon_min + 10.0

    return lat_min, lat_max, lon_min, lon_max

def pixel_to_latlon(row: int, col: int, rows: int, cols: int, lat_min: float, lat_max: float, lon_min: float, lon_max: float):
    """
    Convert pixel coordinates to geographic lat/lon.
    Assumes simple linear mapping (equirectangular approximation).

    For VNP46A2, the sinusoidal projection is more complex, but for 10° tiles,
    a linear approximation is acceptable for city-scale accuracy (~1km precision).

    Args:
        row, col: Pixel coordinates (0-indexed)
        rows, cols: Total dimensions
        lat_min, lat_max, lon_min, lon_max: Tile geographic bounds

    Returns: (lat, lon)
    """
    # Row 0 is at lat_max (top of image), row increases downward
    lat = lat_max - (row / rows) * (lat_max - lat_min)

    # Col 0 is at lon_min (left of image), col increases rightward
    lon = lon_min + (col / cols) * (lon_max - lon_min)

    return lat, lon

def process_hdf5_file(file_path: str, step: int = 100, upload: bool = False):
    """
    Process HDF5 file and optionally upload to MongoDB.
    Requires h5py and numpy to be installed.

    Args:
        file_path: Path to VNP46A2 HDF5 file
        step: Sampling interval (process every Nth pixel)
        upload: If True, upload to MongoDB; if False, dry-run only
    """
    try:
        import h5py
        import numpy as np
    except ImportError:
        logger.error("h5py and numpy are required for processing HDF5 files. Install them with `pip install h5py numpy`.")
        return

    logger.info(f"Processing {file_path} with step {step} (upload={'enabled' if upload else 'disabled'})...")

    # Parse tile ID from filename
    h_tile, v_tile = parse_tile_id(file_path)
    if h_tile is None or v_tile is None:
        logger.error(f"Could not parse tile ID from filename: {file_path}")
        logger.error("Expected format: VNP46A2.AYYYYDDD.hXXvYY.001.hdf")
        return

    logger.info(f"Tile ID: h{h_tile:02d}v{v_tile:02d}")

    # Calculate geographic bounds
    lat_min, lat_max, lon_min, lon_max = tile_to_bounds(h_tile, v_tile)
    logger.info(f"Geographic bounds: Lat [{lat_min:.2f}, {lat_max:.2f}], Lon [{lon_min:.2f}, {lon_max:.2f}]")

    try:
        with h5py.File(file_path, 'r') as f:
            # Navigate to the data field
            # Path based on NASA VNP46A2 structure:
            # HDFEOS/GRIDS/VNP_Grid_DNB/Data Fields/Gap_Filled_DNB_BRDF-Corrected_NTL
            try:
                data_field = f['HDFEOS']['GRIDS']['VIIRS_Grid_DNB_2d']['Data Fields']['Gap_Filled_DNB_BRDF-Corrected_NTL']
                data = data_field[:]

                rows, cols = data.shape
                logger.info(f"Data shape: {rows}x{cols} pixels")

                # Processing loop with geolocation
                count = 0
                batch = []
                collection = get_db_collection() if upload else None

                for r in range(0, rows, step):
                    for c in range(0, cols, step):
                        radiance = float(data[r, c])

                        # Skip invalid/fill values (VNP46A2 uses fill value 65535 for uint16)
                        if radiance < 0 or radiance > 65000:
                            continue

                        mpsas = radiance_to_mpsas(radiance)
                        bortle = get_bortle_class(mpsas)

                        # Calculate lat/lon for this pixel
                        lat, lon = pixel_to_latlon(r, c, rows, cols, lat_min, lat_max, lon_min, lon_max)

                        # Create document
                        doc = {
                            "location": {
                                "type": "Point",
                                "coordinates": [lon, lat]
                            },
                            "mpsas": round(mpsas, 2),
                            "bortle": bortle,
                            "radiance": round(radiance, 2),
                            "source": f"VNP46A2_h{h_tile:02d}v{v_tile:02d}"
                        }

                        batch.append(doc)
                        count += 1

                        # Log sample for verification
                        if count % 1000 == 0:
                            logger.info(f"Processed {count} points. Sample: [{r},{c}] -> ({lat:.4f}, {lon:.4f}), Rad={radiance:.2f}, MPSAS={mpsas:.2f}, Bortle={bortle}")

                        # Batch upload every 1000 documents
                        if upload and len(batch) >= 1000:
                            try:
                                collection.insert_many(batch, ordered=False)
                                logger.info(f"Uploaded batch of {len(batch)} documents")
                                batch = []
                            except BulkWriteError as e:
                                logger.warning(f"Bulk write errors (likely duplicates): {e.details['nInserted']} inserted")
                                batch = []

                # Upload remaining batch
                if upload and len(batch) > 0:
                    try:
                        collection.insert_many(batch, ordered=False)
                        logger.info(f"Uploaded final batch of {len(batch)} documents")
                    except BulkWriteError as e:
                        logger.warning(f"Bulk write errors: {e.details['nInserted']} inserted")

                logger.info(f"Processing complete. Total data points: {count}")

            except KeyError as e:
                logger.error(f"Could not find expected dataset path in HDF5: {e}")
                logger.error("Expected path: HDFEOS/GRIDS/VIIRS_Grid_DNB_2d/Data Fields/Gap_Filled_DNB_BRDF-Corrected_NTL")
                return

    except Exception as e:
        logger.error(f"Error processing HDF5 file: {e}")
        return

def seed_test_data(collection):
    """
    Populate MongoDB with some test data for major cities and dark sky sites.
    """
    logger.info("Seeding test data...")
    
    test_locations = [
        {"name": "New York City", "lat": 40.7128, "lon": -74.0060, "radiance": 100.0}, # Very bright
        {"name": "London", "lat": 51.5074, "lon": -0.1278, "radiance": 80.0},
        {"name": "Tokyo", "lat": 35.6762, "lon": 139.6503, "radiance": 120.0},
        {"name": "Death Valley", "lat": 36.5323, "lon": -116.9325, "radiance": 0.1}, # Dark
        {"name": "Cherry Springs State Park", "lat": 41.6501, "lon": -77.8164, "radiance": 0.2}, # Dark
        {"name": "Mumbai", "lat": 19.0760, "lon": 72.8777, "radiance": 90.0},
    ]
    
    operations = []
    for loc in test_locations:
        mpsas = radiance_to_mpsas(loc['radiance'])
        bortle = get_bortle_class(mpsas)
        
        doc = {
            "location": {
                "type": "Point",
                "coordinates": [loc['lon'], loc['lat']]
            },
            "mpsas": round(mpsas, 2),
            "bortle": bortle,
            "radiance": loc['radiance'],
            "source": "seed_data"
        }
        
        # Upsert based on coordinates to avoid duplicates
        collection.update_one(
            {"location.coordinates": [loc['lon'], loc['lat']]},
            {"$set": doc},
            upsert=True
        )
        logger.info(f"Seeded {loc['name']}: Bortle {bortle}, MPSAS {mpsas:.2f}")

    # Create 2dsphere index if it doesn't exist (though user should have created it)
    try:
        collection.create_index([("location", GEOSPHERE)])
        logger.info("Ensured 2dsphere index on 'location' field.")
    except Exception as e:
        logger.warning(f"Could not create index: {e}")

def main():
    parser = argparse.ArgumentParser(description="Process NASA Light Pollution Data")
    parser.add_argument('--file', type=str, help="Path to HDF5 file")
    parser.add_argument('--seed', action='store_true', help="Seed database with test data")
    parser.add_argument('--upload', action='store_true', help="Upload processed data to MongoDB (default: dry-run only)")
    parser.add_argument('--step', type=int, default=100, help="Sampling interval (process every Nth pixel, default: 100)")

    args = parser.parse_args()

    if args.seed:
        collection = get_db_collection()
        seed_test_data(collection)
    elif args.file:
        process_hdf5_file(args.file, step=args.step, upload=args.upload)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
