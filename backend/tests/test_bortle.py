import unittest
import sys
import os

# Add parent directory to path to import api
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from api.index import calculate_bortle_class

class TestBortleCalculation(unittest.TestCase):
    def test_bortle_classes(self):
        # Test boundary values
        self.assertEqual(calculate_bortle_class(22.00), 1)
        self.assertEqual(calculate_bortle_class(21.99), 1)
        
        self.assertEqual(calculate_bortle_class(21.98), 2)
        self.assertEqual(calculate_bortle_class(21.89), 2)
        
        self.assertEqual(calculate_bortle_class(21.88), 3)
        self.assertEqual(calculate_bortle_class(21.69), 3)
        
        self.assertEqual(calculate_bortle_class(21.68), 4)
        self.assertEqual(calculate_bortle_class(20.49), 4)
        
        self.assertEqual(calculate_bortle_class(20.48), 5)
        self.assertEqual(calculate_bortle_class(19.50), 5)
        
        self.assertEqual(calculate_bortle_class(19.49), 6)
        self.assertEqual(calculate_bortle_class(18.94), 6)
        
        self.assertEqual(calculate_bortle_class(18.93), 7)
        self.assertEqual(calculate_bortle_class(18.38), 7)
        
        self.assertEqual(calculate_bortle_class(18.37), 8)
        self.assertEqual(calculate_bortle_class(17.80), 8)
        
        self.assertEqual(calculate_bortle_class(17.79), 9)
        self.assertEqual(calculate_bortle_class(15.00), 9)

if __name__ == '__main__':
    unittest.main()
