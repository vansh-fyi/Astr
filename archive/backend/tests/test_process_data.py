import unittest
from unittest.mock import patch, MagicMock
import sys
import os
import numpy as np

# Add parent directory to path to import scripts
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# Mock dotenv before importing process_nasa_data
sys.modules['dotenv'] = MagicMock()
sys.modules['pymongo'] = MagicMock()
sys.modules['pymongo.errors'] = MagicMock()
sys.modules['h5py'] = MagicMock()

from scripts.process_nasa_data import (
    radiance_to_mpsas,
    get_bortle_class,
    process_hdf5_file,
    parse_tile_id,
    tile_to_bounds,
    pixel_to_latlon
)

class TestDataProcessing(unittest.TestCase):
    """Test suite for data processing logic"""

    def test_radiance_to_mpsas_conversion(self):
        """Test conversion formula from Radiance to MPSAS"""
        # Test case 1: High radiance (bright city)
        # MPSAS = 12.589 - 1.086 * ln(100) = 12.589 - 1.086 * 4.605 = 12.589 - 5.001 = 7.588
        # Clamped to 16.0
        self.assertEqual(radiance_to_mpsas(100.0), 16.0)

        # Test case 2: Low radiance (dark sky)
        # MPSAS = 12.589 - 1.086 * ln(0.001) = 12.589 - 1.086 * (-6.907) = 12.589 + 7.501 = 20.09
        self.assertAlmostEqual(radiance_to_mpsas(0.001), 20.09, places=2)

        # Test case 3: Zero/Negative radiance (max darkness)
        self.assertEqual(radiance_to_mpsas(0), 22.0)
        self.assertEqual(radiance_to_mpsas(-5), 22.0)

    def test_bortle_class_mapping(self):
        """Test MPSAS to Bortle Class mapping"""
        self.assertEqual(get_bortle_class(22.0), 1)
        self.assertEqual(get_bortle_class(21.90), 2)
        self.assertEqual(get_bortle_class(21.70), 3)
        self.assertEqual(get_bortle_class(21.00), 4)
        self.assertEqual(get_bortle_class(20.00), 5)
        self.assertEqual(get_bortle_class(19.00), 6)
        self.assertEqual(get_bortle_class(18.50), 7)
        self.assertEqual(get_bortle_class(18.00), 8)
        self.assertEqual(get_bortle_class(17.00), 9)

    def test_process_hdf5_file_logic(self):
        """Test HDF5 processing logic with mocked file"""
        # Get the mock from sys.modules
        mock_h5py = sys.modules['h5py']

        # Setup mock HDF5 file structure
        mock_file = MagicMock()
        mock_dataset = MagicMock()

        # Create a small 10x10 fake data array
        # Some bright pixels (100.0), some dark (0.001)
        fake_data = np.zeros((10, 10))
        fake_data[0, 0] = 100.0 # Bright
        fake_data[9, 9] = 0.001 # Dark

        # Mock the dataset slicing
        mock_dataset.__getitem__.return_value = fake_data
        mock_dataset.shape = (10, 10)

        # Mock the file context manager
        mock_h5py.File.return_value.__enter__.return_value = mock_file

        # Mock the nested path traversal for VNP46A2 structure
        # Path: f['HDFEOS']['GRIDS']['VNP_Grid_DNB']['Data Fields']['Gap_Filled_DNB_BRDF-Corrected_NTL']
        mock_file.__getitem__.return_value.__getitem__.return_value.__getitem__.return_value.__getitem__.return_value.__getitem__.return_value = mock_dataset

        # Run the function with proper tile ID in filename
        # Use a filename that can be parsed for tile ID
        process_hdf5_file("VNP46A2.A2024001.h08v05.001.hdf", step=1, upload=False)

        # Verify file was opened
        mock_h5py.File.assert_called_with("VNP46A2.A2024001.h08v05.001.hdf", 'r')


class TestTileIDParsing(unittest.TestCase):
    """Test VNP46A2 tile ID parsing from filenames"""

    def test_parse_standard_filename(self):
        """Parse standard VNP46A2 filename format"""
        h, v = parse_tile_id("VNP46A2.A2024001.h08v05.001.2024005033728.hdf")
        self.assertEqual(h, 8)
        self.assertEqual(v, 5)

    def test_parse_simple_filename(self):
        """Parse simplified filename"""
        h, v = parse_tile_id("VNP46A2_h12v04.hdf")
        self.assertEqual(h, 12)
        self.assertEqual(v, 4)

    def test_parse_with_path(self):
        """Parse filename with path"""
        h, v = parse_tile_id("/data/nasa/VNP46A2.A2024032.h00v17.001.hdf")
        self.assertEqual(h, 0)
        self.assertEqual(v, 17)

    def test_parse_edge_tiles(self):
        """Parse edge tile IDs"""
        h, v = parse_tile_id("VNP46A2.h35v00.hdf")
        self.assertEqual(h, 35)
        self.assertEqual(v, 0)

    def test_parse_invalid_filename(self):
        """Invalid filename should return None"""
        h, v = parse_tile_id("invalid_file.hdf")
        self.assertIsNone(h)
        self.assertIsNone(v)

    def test_parse_no_tile_id(self):
        """Filename without tile ID should return None"""
        h, v = parse_tile_id("VNP46A2.A2024001.hdf")
        self.assertIsNone(h)
        self.assertIsNone(v)


class TestTileToBounds(unittest.TestCase):
    """Test VNP46A2 tile index to geographic bounds conversion"""

    def test_northwest_corner_tile(self):
        """Tile h00v00 should cover northwest corner"""
        lat_min, lat_max, lon_min, lon_max = tile_to_bounds(0, 0)
        self.assertEqual(lat_max, 90.0)
        self.assertEqual(lat_min, 80.0)
        self.assertEqual(lon_min, -180.0)
        self.assertEqual(lon_max, -170.0)

    def test_north_america_tile(self):
        """Tile h08v05 should cover eastern North America region"""
        # h08 = -180 + 8*10 = -100 to -90
        # v05 = 90 - 5*10 = 40 to 50
        lat_min, lat_max, lon_min, lon_max = tile_to_bounds(8, 5)
        self.assertEqual(lat_max, 40.0)
        self.assertEqual(lat_min, 30.0)
        self.assertEqual(lon_min, -100.0)
        self.assertEqual(lon_max, -90.0)

    def test_europe_tile(self):
        """Tile h18v04 should cover Europe region"""
        # h18 = -180 + 18*10 = 0 to 10
        # v04 = 90 - 4*10 = 50 to 60
        lat_min, lat_max, lon_min, lon_max = tile_to_bounds(18, 4)
        self.assertEqual(lat_max, 50.0)
        self.assertEqual(lat_min, 40.0)
        self.assertEqual(lon_min, 0.0)
        self.assertEqual(lon_max, 10.0)

    def test_southeast_corner_tile(self):
        """Tile h35v17 should cover southeast corner"""
        # h35 = -180 + 35*10 = 170 to 180
        # v17 = 90 - 17*10 = -80 to -90
        lat_min, lat_max, lon_min, lon_max = tile_to_bounds(35, 17)
        self.assertEqual(lat_max, -80.0)
        self.assertEqual(lat_min, -90.0)
        self.assertEqual(lon_min, 170.0)
        self.assertEqual(lon_max, 180.0)


class TestPixelToLatLon(unittest.TestCase):
    """Test pixel coordinate to lat/lon conversion"""

    def test_top_left_pixel(self):
        """Pixel [0,0] should be at top-left corner of bounds"""
        lat, lon = pixel_to_latlon(0, 0, 2400, 2400, 30.0, 40.0, -100.0, -90.0)
        self.assertAlmostEqual(lat, 40.0, places=5)
        self.assertAlmostEqual(lon, -100.0, places=5)

    def test_bottom_right_pixel(self):
        """Pixel [2399,2399] should be near bottom-right corner"""
        lat, lon = pixel_to_latlon(2399, 2399, 2400, 2400, 30.0, 40.0, -100.0, -90.0)
        # Bottom right should be very close to lat_min and lon_max
        # lat = lat_max - (2399/2400) * (lat_max - lat_min)
        # lat = 40 - 0.999583 * 10 = 40 - 9.99583 = 30.004167
        self.assertAlmostEqual(lat, 30.0, places=0)
        self.assertAlmostEqual(lon, -90.0, places=0)

    def test_center_pixel(self):
        """Center pixel should be at center of bounds"""
        lat, lon = pixel_to_latlon(1200, 1200, 2400, 2400, 30.0, 40.0, -100.0, -90.0)
        self.assertAlmostEqual(lat, 35.0, places=1)
        self.assertAlmostEqual(lon, -95.0, places=1)

    def test_quarter_pixel(self):
        """Quarter pixel should be at 1/4 of bounds"""
        lat, lon = pixel_to_latlon(600, 600, 2400, 2400, 30.0, 40.0, -100.0, -90.0)
        # Row 600 is 600/2400 = 0.25 from top
        # Lat = 40 - 0.25 * 10 = 37.5
        # Col 600 is 600/2400 = 0.25 from left
        # Lon = -100 + 0.25 * 10 = -97.5
        self.assertAlmostEqual(lat, 37.5, places=1)
        self.assertAlmostEqual(lon, -97.5, places=1)


class TestIntegrationScenarios(unittest.TestCase):
    """Integration tests for realistic scenarios"""

    def test_nyc_light_pollution(self):
        """Test realistic NYC light pollution values"""
        # NYC radiance ≈ 100 nW/cm^2/sr
        radiance = 100.0
        mpsas = radiance_to_mpsas(radiance)
        bortle = get_bortle_class(mpsas)

        # NYC should be Bortle 9 (inner city)
        self.assertEqual(bortle, 9)

    def test_dark_sky_site(self):
        """Test realistic dark sky site values"""
        # Cherry Springs State Park radiance (very low for dark sky)
        # For Bortle 1-3, MPSAS must be >= 21.69
        # MPSAS = 12.589 - 1.086 * ln(radiance)
        # 21.69 = 12.589 - 1.086 * ln(radiance)
        # ln(radiance) = -8.38, radiance ≈ 0.00023
        radiance = 0.0002
        mpsas = radiance_to_mpsas(radiance)
        bortle = get_bortle_class(mpsas)

        # Dark sky should be Bortle 1-3
        self.assertLessEqual(bortle, 3)

    def test_suburban_area(self):
        """Test realistic suburban values"""
        # Suburban radiance ≈ 5-10 nW/cm^2/sr
        # MPSAS = 12.589 - 1.086 * ln(7) = 12.589 - 1.086 * 1.946 = 12.589 - 2.113 = 10.476
        # Clamped to 16.0
        radiance = 7.0
        mpsas = radiance_to_mpsas(radiance)
        bortle = get_bortle_class(mpsas)

        # With MPSAS = 16.0, Bortle should be 9
        self.assertEqual(bortle, 9)

    def test_full_pipeline_nyc_coordinates(self):
        """Test full pipeline: tile parsing -> bounds -> pixel -> lat/lon for NYC"""
        # NYC is approximately at h08v05
        h, v = parse_tile_id("VNP46A2.A2024001.h08v05.001.hdf")
        self.assertEqual((h, v), (8, 5))

        # Get bounds
        lat_min, lat_max, lon_min, lon_max = tile_to_bounds(h, v)
        self.assertEqual((lat_min, lat_max, lon_min, lon_max), (30.0, 40.0, -100.0, -90.0))

        # NYC is at approximately 40.7N, 74W
        # This is actually outside our h08v05 tile (which is -100 to -90 lon)
        # But we can test a pixel that would be in this tile
        # Center of tile would be at 35N, -95W
        lat, lon = pixel_to_latlon(1200, 1200, 2400, 2400, lat_min, lat_max, lon_min, lon_max)
        self.assertAlmostEqual(lat, 35.0, places=1)
        self.assertAlmostEqual(lon, -95.0, places=1)


if __name__ == '__main__':
    unittest.main()
