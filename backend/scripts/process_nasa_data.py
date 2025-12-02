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

def process_hdf5_file(file_path: str, step: int = 100):
    """
    Process HDF5 file and upload to MongoDB.
    Requires h5py to be installed.
    """
    try:
        import h5py
        import numpy as np
    except ImportError:
        logger.error("h5py and numpy are required for processing HDF5 files. Install them with `pip install h5py numpy`.")
        return

    logger.info(f"Processing {file_path} with step {step}...")
    
    # Placeholder for actual HDF5 reading logic
    # In a real scenario, we would:
    # 1. Open file: f = h5py.File(file_path, 'r')
    # 2. Access dataset: data = f['HDFEOS']['GRIDS']['VNP_Grid_DNB']['Data Fields']['Gap_Filled_DNB_BRDF-Corrected_NTL']
    # 3. Iterate over lat/lon grid with 'step'
    # 4. Convert radiance to MPSAS
    # 5. Create GeoJSON points
    
    logger.warning("HDF5 processing logic is a template. Please implement specific dataset path traversal based on the exact HDF5 structure.")

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
    
    args = parser.parse_args()
    
    collection = get_db_collection()
    
    if args.seed:
        seed_test_data(collection)
    elif args.file:
        process_hdf5_file(args.file)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
