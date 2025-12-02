import unittest
import sys
import os
from unittest.mock import patch, MagicMock

# Add parent directory to path to import api module
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from api.index import app, calculate_bortle_class

class TestHealthEndpoint(unittest.TestCase):
    """Test suite for /api/health endpoint"""

    def setUp(self):
        """Set up test client"""
        self.client = app.test_client()
        self.client.testing = True

    def test_health_check_success(self):
        """Test health check returns 200 OK"""
        response = self.client.get('/api/health')
        self.assertEqual(response.status_code, 200)

        data = response.get_json()
        self.assertEqual(data['status'], 'healthy')
        self.assertEqual(data['service'], 'Astr Backend API')
        self.assertIn('database', data)

class TestRootEndpoint(unittest.TestCase):
    """Test suite for / root endpoint"""

    def setUp(self):
        """Set up test client"""
        self.client = app.test_client()
        self.client.testing = True

    def test_root_endpoint(self):
        """Test root endpoint returns API info"""
        response = self.client.get('/')
        self.assertEqual(response.status_code, 200)

        data = response.get_json()
        self.assertIn('message', data)
        self.assertIn('version', data)
        self.assertIn('endpoints', data)

class TestLightPollutionEndpoint(unittest.TestCase):
    """Test suite for /api/light-pollution endpoint"""

    def setUp(self):
        """Set up test client"""
        self.client = app.test_client()
        self.client.testing = True

    def test_missing_lat_parameter(self):
        """Test endpoint returns 400 when lat parameter is missing"""
        response = self.client.get('/api/light-pollution?lon=50.0')
        self.assertEqual(response.status_code, 400)

        data = response.get_json()
        self.assertIn('error', data)
        self.assertIn('lat', data['message'].lower())

    def test_missing_lon_parameter(self):
        """Test endpoint returns 400 when lon parameter is missing"""
        response = self.client.get('/api/light-pollution?lat=40.0')
        self.assertEqual(response.status_code, 400)

        data = response.get_json()
        self.assertIn('error', data)
        self.assertIn('lon', data['message'].lower())

    def test_missing_both_parameters(self):
        """Test endpoint returns 400 when both parameters are missing"""
        response = self.client.get('/api/light-pollution')
        self.assertEqual(response.status_code, 400)

        data = response.get_json()
        self.assertIn('error', data)

    def test_invalid_latitude_too_high(self):
        """Test endpoint returns 400 for latitude > 90"""
        response = self.client.get('/api/light-pollution?lat=95.0&lon=50.0')
        self.assertEqual(response.status_code, 400)

        data = response.get_json()
        self.assertIn('error', data)
        self.assertIn('latitude', data['error'].lower())

    def test_invalid_latitude_too_low(self):
        """Test endpoint returns 400 for latitude < -90"""
        response = self.client.get('/api/light-pollution?lat=-95.0&lon=50.0')
        self.assertEqual(response.status_code, 400)

        data = response.get_json()
        self.assertIn('error', data)
        self.assertIn('latitude', data['error'].lower())

    def test_invalid_longitude_too_high(self):
        """Test endpoint returns 400 for longitude > 180"""
        response = self.client.get('/api/light-pollution?lat=40.0&lon=200.0')
        self.assertEqual(response.status_code, 400)

        data = response.get_json()
        self.assertIn('error', data)
        self.assertIn('longitude', data['error'].lower())

    def test_invalid_longitude_too_low(self):
        """Test endpoint returns 400 for longitude < -180"""
        response = self.client.get('/api/light-pollution?lat=40.0&lon=-200.0')
        self.assertEqual(response.status_code, 400)

        data = response.get_json()
        self.assertIn('error', data)
        self.assertIn('longitude', data['error'].lower())

    def test_valid_coordinates_fallback(self):
        """Test endpoint returns fallback data for valid coordinates when DB unavailable"""
        response = self.client.get('/api/light-pollution?lat=40.7128&lon=-74.0060')
        self.assertEqual(response.status_code, 200)

        data = response.get_json()
        self.assertIn('lat', data)
        self.assertIn('lon', data)
        self.assertIn('mpsas', data)
        self.assertIn('bortle_class', data)
        self.assertEqual(data['lat'], 40.7128)
        self.assertEqual(data['lon'], -74.0060)

    @patch('api.index.get_db')
    def test_with_database_connection(self, mock_get_db):
        """Test endpoint with mocked database connection"""
        # Mock database that returns no results
        mock_db = MagicMock()
        mock_collection = MagicMock()
        mock_collection.find_one.return_value = None
        mock_db.light_pollution = mock_collection
        mock_get_db.return_value = mock_db

        response = self.client.get('/api/light-pollution?lat=40.0&lon=-74.0')
        self.assertEqual(response.status_code, 200)

        data = response.get_json()
        self.assertIn('fallback', data)

    @patch('api.index.get_db')
    def test_with_database_data(self, mock_get_db):
        """Test endpoint with mocked database data"""
        # Mock database that returns data
        mock_db = MagicMock()
        mock_collection = MagicMock()
        mock_collection.find_one.return_value = {
            'location': {'coordinates': [-74.0, 40.0]},
            'mpsas': 19.5
        }
        mock_db.light_pollution = mock_collection
        mock_get_db.return_value = mock_db

        response = self.client.get('/api/light-pollution?lat=40.0&lon=-74.0')
        self.assertEqual(response.status_code, 200)

        data = response.get_json()
        self.assertEqual(data['mpsas'], 19.5)
        self.assertEqual(data['fallback'], False)
        self.assertIn('bortle_class', data)

class TestBortleClassCalculation(unittest.TestCase):
    """Test suite for Bortle class calculation"""

    def test_bortle_class_1_excellent(self):
        """Test MPSAS >= 21.7 returns Bortle Class 1"""
        self.assertEqual(calculate_bortle_class(22.0), 1)
        self.assertEqual(calculate_bortle_class(21.7), 1)

    def test_bortle_class_2_typical_dark(self):
        """Test MPSAS >= 21.5 returns Bortle Class 2"""
        self.assertEqual(calculate_bortle_class(21.6), 2)
        self.assertEqual(calculate_bortle_class(21.5), 2)

    def test_bortle_class_3_rural(self):
        """Test MPSAS >= 21.3 returns Bortle Class 3"""
        self.assertEqual(calculate_bortle_class(21.4), 3)
        self.assertEqual(calculate_bortle_class(21.3), 3)

    def test_bortle_class_4_transition(self):
        """Test MPSAS >= 20.4 returns Bortle Class 4"""
        self.assertEqual(calculate_bortle_class(21.0), 4)
        self.assertEqual(calculate_bortle_class(20.4), 4)

    def test_bortle_class_5_suburban(self):
        """Test MPSAS >= 19.1 returns Bortle Class 5"""
        self.assertEqual(calculate_bortle_class(20.0), 5)
        self.assertEqual(calculate_bortle_class(19.1), 5)

    def test_bortle_class_6_bright_suburban(self):
        """Test MPSAS >= 18.0 returns Bortle Class 6"""
        self.assertEqual(calculate_bortle_class(19.0), 6)
        self.assertEqual(calculate_bortle_class(18.5), 6)
        self.assertEqual(calculate_bortle_class(18.0), 6)

    def test_bortle_class_8_city(self):
        """Test MPSAS >= 17.0 returns Bortle Class 8"""
        self.assertEqual(calculate_bortle_class(17.5), 8)
        self.assertEqual(calculate_bortle_class(17.0), 8)

    def test_bortle_class_9_inner_city(self):
        """Test MPSAS < 17.0 returns Bortle Class 9"""
        self.assertEqual(calculate_bortle_class(16.5), 9)
        self.assertEqual(calculate_bortle_class(15.0), 9)

if __name__ == '__main__':
    unittest.main()
