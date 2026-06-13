import os
import sys
import argparse
import logging
from dotenv import load_dotenv

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv(os.path.join(os.path.dirname(__file__), '../.env'))

def download_data(tile: str, date_start: str, date_end: str, output_dir: str = ".", global_coverage: bool = False):
    """
    Download VNP46A2 data for a specific tile (or globally) and date range.
    """
    try:
        import earthaccess
    except ImportError:
        logger.error("earthaccess library is required. Install it with `pip install earthaccess`.")
        sys.exit(1)

    # Authenticate
    auth = earthaccess.login(strategy="interactive", persist=True)
    if not auth.authenticated:
        logger.error("Authentication failed. Please check your credentials.")
        sys.exit(1)

    if global_coverage:
        logger.info(f"Searching for GLOBAL VNP46A2 data from {date_start} to {date_end}...")
        # Global bounding box
        results = earthaccess.search_data(
            short_name="VNP46A2",
            temporal=(date_start, date_end),
            bounding_box=(-180, -90, 180, 90),
            count=-1 # Unlimited
        )
    else:
        logger.info(f"Searching for VNP46A2 data for tile {tile} from {date_start} to {date_end}...")
        results = earthaccess.search_data(
            short_name="VNP46A2",
            temporal=(date_start, date_end),
            granule_name=f"*{tile}*",
            count=10
        )

    if not results:
        logger.warning("No results found. Check your dates and tile ID.")
        return

    logger.info(f"Found {len(results)} files.")
    
    # Download
    os.makedirs(output_dir, exist_ok=True)
    downloaded_files = earthaccess.download(results, output_dir)
    
    logger.info(f"Downloaded {len(downloaded_files)} files to {output_dir}")

def main():
    parser = argparse.ArgumentParser(description="Download NASA VNP46A2 Data")
    parser.add_argument('--tile', type=str, help="Tile ID (e.g., h12v04). Required unless --global is used.")
    parser.add_argument('--start', type=str, required=True, help="Start date (YYYY-MM-DD)")
    parser.add_argument('--end', type=str, required=True, help="End date (YYYY-MM-DD)")
    parser.add_argument('--output', type=str, default=".", help="Output directory")
    parser.add_argument('--global_coverage', action='store_true', help="Download data for the entire world")

    args = parser.parse_args()

    if not args.tile and not args.global_coverage:
        parser.error("--tile is required unless --global_coverage is set.")

    download_data(args.tile, args.start, args.end, args.output, args.global_coverage)

if __name__ == "__main__":
    main()
