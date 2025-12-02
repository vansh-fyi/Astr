import unittest

def calculate_bortle_class(mpsas):
    """
    Convert MPSAS to Bortle Dark Sky Scale (1-9)
    Copied from backend/api/index.py for isolation testing
    """
    if mpsas >= 21.99:
        return 1  # Excellent dark sky
    elif mpsas >= 21.89:
        return 2  # Truly dark sky
    elif mpsas >= 21.69:
        return 3  # Rural sky
    elif mpsas >= 20.49:
        return 4  # Rural/suburban transition
    elif mpsas >= 19.50:
        return 5  # Suburban sky
    elif mpsas >= 18.94:
        return 6  # Bright suburban sky
    elif mpsas >= 18.38:
        return 7  # Suburban/urban transition
    elif mpsas >= 17.80:
        return 8  # City sky
    else:
        return 9  # Inner city sky

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
