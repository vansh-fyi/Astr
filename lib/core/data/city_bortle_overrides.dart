/// City-based Bortle scale overrides for accurate light pollution data
///
/// This data provides accurate Bortle classifications for major urban centers
/// worldwide, addressing gaps in the World Atlas 2015 PNG map data.
///
/// Data sources:
/// - Light Pollution Map (lightpollutionmap.info)
/// - Dark Site Finder
/// - International Dark-Sky Association
/// - Local astronomical society reports
///
/// Last updated: December 2025
library;

class CityBortleOverride { // Radius of influence in kilometers

  const CityBortleOverride({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.bortleClass,
    this.radiusKm = 30.0, // Default 30km radius
  });
  final String name;
  final String country;
  final double latitude;
  final double longitude;
  final int bortleClass;
  final double radiusKm;
}

/// Comprehensive database of city Bortle values
/// Organized by continent for easier maintenance
class CityBortleDatabase {
  static const List<CityBortleOverride> cities = <CityBortleOverride>[
    // ========== ASIA ==========

    // India
    CityBortleOverride(name: 'Delhi', country: 'India', latitude: 28.6139, longitude: 77.2090, bortleClass: 9, radiusKm: 40),
    CityBortleOverride(name: 'Mumbai', country: 'India', latitude: 19.0760, longitude: 72.8777, bortleClass: 9, radiusKm: 40),
    CityBortleOverride(name: 'Bangalore', country: 'India', latitude: 12.9716, longitude: 77.5946, bortleClass: 8, radiusKm: 35),
    CityBortleOverride(name: 'Kolkata', country: 'India', latitude: 22.5726, longitude: 88.3639, bortleClass: 9, radiusKm: 35),
    CityBortleOverride(name: 'Chennai', country: 'India', latitude: 13.0827, longitude: 80.2707, bortleClass: 8, radiusKm: 35),
    CityBortleOverride(name: 'Hyderabad', country: 'India', latitude: 17.3850, longitude: 78.4867, bortleClass: 8, radiusKm: 35),
    CityBortleOverride(name: 'Ahmedabad', country: 'India', latitude: 23.0225, longitude: 72.5714, bortleClass: 8),
    CityBortleOverride(name: 'Pune', country: 'India', latitude: 18.5204, longitude: 73.8567, bortleClass: 8),

    // China
    CityBortleOverride(name: 'Shanghai', country: 'China', latitude: 31.2304, longitude: 121.4737, bortleClass: 9, radiusKm: 50),
    CityBortleOverride(name: 'Beijing', country: 'China', latitude: 39.9042, longitude: 116.4074, bortleClass: 9, radiusKm: 50),
    CityBortleOverride(name: 'Guangzhou', country: 'China', latitude: 23.1291, longitude: 113.2644, bortleClass: 9, radiusKm: 40),
    CityBortleOverride(name: 'Shenzhen', country: 'China', latitude: 22.5431, longitude: 114.0579, bortleClass: 9, radiusKm: 40),
    CityBortleOverride(name: 'Chongqing', country: 'China', latitude: 29.4316, longitude: 106.9123, bortleClass: 8, radiusKm: 40),
    CityBortleOverride(name: 'Tianjin', country: 'China', latitude: 39.3434, longitude: 117.3616, bortleClass: 9, radiusKm: 35),
    CityBortleOverride(name: 'Wuhan', country: 'China', latitude: 30.5928, longitude: 114.3055, bortleClass: 8, radiusKm: 35),
    CityBortleOverride(name: 'Chengdu', country: 'China', latitude: 30.5728, longitude: 104.0668, bortleClass: 8, radiusKm: 35),
    CityBortleOverride(name: 'Nanjing', country: 'China', latitude: 32.0603, longitude: 118.7969, bortleClass: 8),
    CityBortleOverride(name: "Xi'an", country: 'China', latitude: 34.3416, longitude: 108.9398, bortleClass: 8),

    // Japan
    CityBortleOverride(name: 'Tokyo', country: 'Japan', latitude: 35.6762, longitude: 139.6503, bortleClass: 9, radiusKm: 50),
    CityBortleOverride(name: 'Osaka', country: 'Japan', latitude: 34.6937, longitude: 135.5023, bortleClass: 9, radiusKm: 40),
    CityBortleOverride(name: 'Yokohama', country: 'Japan', latitude: 35.4437, longitude: 139.6380, bortleClass: 9),
    CityBortleOverride(name: 'Nagoya', country: 'Japan', latitude: 35.1815, longitude: 136.9066, bortleClass: 8),
    CityBortleOverride(name: 'Sapporo', country: 'Japan', latitude: 43.0642, longitude: 141.3469, bortleClass: 7, radiusKm: 25),
    CityBortleOverride(name: 'Fukuoka', country: 'Japan', latitude: 33.5904, longitude: 130.4017, bortleClass: 8, radiusKm: 25),

    // South Korea
    CityBortleOverride(name: 'Seoul', country: 'South Korea', latitude: 37.5665, longitude: 126.9780, bortleClass: 9, radiusKm: 40),
    CityBortleOverride(name: 'Busan', country: 'South Korea', latitude: 35.1796, longitude: 129.0756, bortleClass: 8),
    CityBortleOverride(name: 'Incheon', country: 'South Korea', latitude: 37.4563, longitude: 126.7052, bortleClass: 8, radiusKm: 25),
    CityBortleOverride(name: 'Daegu', country: 'South Korea', latitude: 35.8714, longitude: 128.6014, bortleClass: 8, radiusKm: 25),

    // Southeast Asia
    CityBortleOverride(name: 'Singapore', country: 'Singapore', latitude: 1.3521, longitude: 103.8198, bortleClass: 9, radiusKm: 25),
    CityBortleOverride(name: 'Bangkok', country: 'Thailand', latitude: 13.7563, longitude: 100.5018, bortleClass: 9, radiusKm: 40),
    CityBortleOverride(name: 'Jakarta', country: 'Indonesia', latitude: -6.2088, longitude: 106.8456, bortleClass: 9, radiusKm: 40),
    CityBortleOverride(name: 'Manila', country: 'Philippines', latitude: 14.5995, longitude: 120.9842, bortleClass: 9, radiusKm: 35),
    CityBortleOverride(name: 'Ho Chi Minh City', country: 'Vietnam', latitude: 10.8231, longitude: 106.6297, bortleClass: 8),
    CityBortleOverride(name: 'Kuala Lumpur', country: 'Malaysia', latitude: 3.1390, longitude: 101.6869, bortleClass: 8),
    CityBortleOverride(name: 'Hanoi', country: 'Vietnam', latitude: 21.0285, longitude: 105.8542, bortleClass: 8, radiusKm: 25),

    // Middle East
    CityBortleOverride(name: 'Dubai', country: 'UAE', latitude: 25.2048, longitude: 55.2708, bortleClass: 9, radiusKm: 35),
    CityBortleOverride(name: 'Abu Dhabi', country: 'UAE', latitude: 24.4539, longitude: 54.3773, bortleClass: 8),
    CityBortleOverride(name: 'Riyadh', country: 'Saudi Arabia', latitude: 24.7136, longitude: 46.6753, bortleClass: 8, radiusKm: 35),
    CityBortleOverride(name: 'Jeddah', country: 'Saudi Arabia', latitude: 21.4858, longitude: 39.1925, bortleClass: 8),
    CityBortleOverride(name: 'Tehran', country: 'Iran', latitude: 35.6892, longitude: 51.3890, bortleClass: 8, radiusKm: 35),
    CityBortleOverride(name: 'Istanbul', country: 'Turkey', latitude: 41.0082, longitude: 28.9784, bortleClass: 9, radiusKm: 40),
    CityBortleOverride(name: 'Ankara', country: 'Turkey', latitude: 39.9334, longitude: 32.8597, bortleClass: 7, radiusKm: 25),
    CityBortleOverride(name: 'Tel Aviv', country: 'Israel', latitude: 32.0853, longitude: 34.7818, bortleClass: 8, radiusKm: 25),

    // ========== EUROPE ==========

    // United Kingdom
    CityBortleOverride(name: 'London', country: 'UK', latitude: 51.5074, longitude: -0.1278, bortleClass: 8, radiusKm: 50),
    CityBortleOverride(name: 'Birmingham', country: 'UK', latitude: 52.4862, longitude: -1.8904, bortleClass: 7, radiusKm: 25),
    CityBortleOverride(name: 'Manchester', country: 'UK', latitude: 53.4808, longitude: -2.2426, bortleClass: 7, radiusKm: 25),
    CityBortleOverride(name: 'Glasgow', country: 'UK', latitude: 55.8642, longitude: -4.2518, bortleClass: 7, radiusKm: 20),

    // France
    CityBortleOverride(name: 'Paris', country: 'France', latitude: 48.8566, longitude: 2.3522, bortleClass: 9, radiusKm: 45),
    CityBortleOverride(name: 'Lyon', country: 'France', latitude: 45.7640, longitude: 4.8357, bortleClass: 7, radiusKm: 25),
    CityBortleOverride(name: 'Marseille', country: 'France', latitude: 43.2965, longitude: 5.3698, bortleClass: 7, radiusKm: 25),
    CityBortleOverride(name: 'Toulouse', country: 'France', latitude: 43.6047, longitude: 1.4442, bortleClass: 7, radiusKm: 20),

    // Germany
    CityBortleOverride(name: 'Berlin', country: 'Germany', latitude: 52.5200, longitude: 13.4050, bortleClass: 8, radiusKm: 35),
    CityBortleOverride(name: 'Munich', country: 'Germany', latitude: 48.1351, longitude: 11.5820, bortleClass: 8),
    CityBortleOverride(name: 'Hamburg', country: 'Germany', latitude: 53.5511, longitude: 9.9937, bortleClass: 7, radiusKm: 25),
    CityBortleOverride(name: 'Frankfurt', country: 'Germany', latitude: 50.1109, longitude: 8.6821, bortleClass: 8, radiusKm: 25),
    CityBortleOverride(name: 'Cologne', country: 'Germany', latitude: 50.9375, longitude: 6.9603, bortleClass: 7, radiusKm: 20),

    // Italy
    CityBortleOverride(name: 'Rome', country: 'Italy', latitude: 41.9028, longitude: 12.4964, bortleClass: 8, radiusKm: 35),
    CityBortleOverride(name: 'Milan', country: 'Italy', latitude: 45.4642, longitude: 9.1900, bortleClass: 8),
    CityBortleOverride(name: 'Naples', country: 'Italy', latitude: 40.8518, longitude: 14.2681, bortleClass: 8, radiusKm: 25),
    CityBortleOverride(name: 'Turin', country: 'Italy', latitude: 45.0703, longitude: 7.6869, bortleClass: 7, radiusKm: 20),

    // Spain
    CityBortleOverride(name: 'Madrid', country: 'Spain', latitude: 40.4168, longitude: -3.7038, bortleClass: 8, radiusKm: 35),
    CityBortleOverride(name: 'Barcelona', country: 'Spain', latitude: 41.3851, longitude: 2.1734, bortleClass: 8),
    CityBortleOverride(name: 'Valencia', country: 'Spain', latitude: 39.4699, longitude: -0.3763, bortleClass: 7, radiusKm: 20),
    CityBortleOverride(name: 'Seville', country: 'Spain', latitude: 37.3891, longitude: -5.9845, bortleClass: 7, radiusKm: 20),

    // Netherlands
    CityBortleOverride(name: 'Amsterdam', country: 'Netherlands', latitude: 52.3676, longitude: 4.9041, bortleClass: 8, radiusKm: 25),
    CityBortleOverride(name: 'Rotterdam', country: 'Netherlands', latitude: 51.9225, longitude: 4.4792, bortleClass: 8, radiusKm: 20),

    // Belgium
    CityBortleOverride(name: 'Brussels', country: 'Belgium', latitude: 50.8503, longitude: 4.3517, bortleClass: 8, radiusKm: 25),
    CityBortleOverride(name: 'Antwerp', country: 'Belgium', latitude: 51.2194, longitude: 4.4025, bortleClass: 7, radiusKm: 15),

    // Russia
    CityBortleOverride(name: 'Moscow', country: 'Russia', latitude: 55.7558, longitude: 37.6173, bortleClass: 9, radiusKm: 50),
    CityBortleOverride(name: 'Saint Petersburg', country: 'Russia', latitude: 59.9343, longitude: 30.3351, bortleClass: 8, radiusKm: 35),
    CityBortleOverride(name: 'Novosibirsk', country: 'Russia', latitude: 55.0084, longitude: 82.9357, bortleClass: 7, radiusKm: 25),
    CityBortleOverride(name: 'Yekaterinburg', country: 'Russia', latitude: 56.8389, longitude: 60.6057, bortleClass: 7, radiusKm: 25),

    // Poland
    CityBortleOverride(name: 'Warsaw', country: 'Poland', latitude: 52.2297, longitude: 21.0122, bortleClass: 8),
    CityBortleOverride(name: 'Krakow', country: 'Poland', latitude: 50.0647, longitude: 19.9450, bortleClass: 7, radiusKm: 20),

    // Other Europe
    CityBortleOverride(name: 'Vienna', country: 'Austria', latitude: 48.2082, longitude: 16.3738, bortleClass: 8, radiusKm: 25),
    CityBortleOverride(name: 'Prague', country: 'Czech Republic', latitude: 50.0755, longitude: 14.4378, bortleClass: 7, radiusKm: 20),
    CityBortleOverride(name: 'Budapest', country: 'Hungary', latitude: 47.4979, longitude: 19.0402, bortleClass: 7, radiusKm: 25),
    CityBortleOverride(name: 'Athens', country: 'Greece', latitude: 37.9838, longitude: 23.7275, bortleClass: 8),
    CityBortleOverride(name: 'Lisbon', country: 'Portugal', latitude: 38.7223, longitude: -9.1393, bortleClass: 7, radiusKm: 25),
    CityBortleOverride(name: 'Stockholm', country: 'Sweden', latitude: 59.3293, longitude: 18.0686, bortleClass: 7, radiusKm: 25),
    CityBortleOverride(name: 'Copenhagen', country: 'Denmark', latitude: 55.6761, longitude: 12.5683, bortleClass: 7, radiusKm: 20),
    CityBortleOverride(name: 'Oslo', country: 'Norway', latitude: 59.9139, longitude: 10.7522, bortleClass: 6, radiusKm: 20),
    CityBortleOverride(name: 'Helsinki', country: 'Finland', latitude: 60.1699, longitude: 24.9384, bortleClass: 6, radiusKm: 20),

    // ========== NORTH AMERICA ==========

    // United States
    CityBortleOverride(name: 'New York', country: 'USA', latitude: 40.7128, longitude: -74.0060, bortleClass: 9, radiusKm: 60),
    CityBortleOverride(name: 'Los Angeles', country: 'USA', latitude: 34.0522, longitude: -118.2437, bortleClass: 9, radiusKm: 60),
    CityBortleOverride(name: 'Chicago', country: 'USA', latitude: 41.8781, longitude: -87.6298, bortleClass: 9, radiusKm: 50),
    CityBortleOverride(name: 'Houston', country: 'USA', latitude: 29.7604, longitude: -95.3698, bortleClass: 8, radiusKm: 45),
    CityBortleOverride(name: 'Phoenix', country: 'USA', latitude: 33.4484, longitude: -112.0740, bortleClass: 8, radiusKm: 40),
    CityBortleOverride(name: 'Philadelphia', country: 'USA', latitude: 39.9526, longitude: -75.1652, bortleClass: 9, radiusKm: 40),
    CityBortleOverride(name: 'San Antonio', country: 'USA', latitude: 29.4241, longitude: -98.4936, bortleClass: 7),
    CityBortleOverride(name: 'San Diego', country: 'USA', latitude: 32.7157, longitude: -117.1611, bortleClass: 8, radiusKm: 35),
    CityBortleOverride(name: 'Dallas', country: 'USA', latitude: 32.7767, longitude: -96.7970, bortleClass: 8, radiusKm: 40),
    CityBortleOverride(name: 'San Jose', country: 'USA', latitude: 37.3382, longitude: -121.8863, bortleClass: 8),
    CityBortleOverride(name: 'Austin', country: 'USA', latitude: 30.2672, longitude: -97.7431, bortleClass: 7),
    CityBortleOverride(name: 'Jacksonville', country: 'USA', latitude: 30.3322, longitude: -81.6557, bortleClass: 7, radiusKm: 25),
    CityBortleOverride(name: 'San Francisco', country: 'USA', latitude: 37.7749, longitude: -122.4194, bortleClass: 9, radiusKm: 35),
    CityBortleOverride(name: 'Columbus', country: 'USA', latitude: 39.9612, longitude: -82.9988, bortleClass: 7, radiusKm: 25),
    CityBortleOverride(name: 'Fort Worth', country: 'USA', latitude: 32.7555, longitude: -97.3308, bortleClass: 8, radiusKm: 25),
    CityBortleOverride(name: 'Indianapolis', country: 'USA', latitude: 39.7684, longitude: -86.1581, bortleClass: 7, radiusKm: 25),
    CityBortleOverride(name: 'Charlotte', country: 'USA', latitude: 35.2271, longitude: -80.8431, bortleClass: 7, radiusKm: 25),
    CityBortleOverride(name: 'Seattle', country: 'USA', latitude: 47.6062, longitude: -122.3321, bortleClass: 8),
    CityBortleOverride(name: 'Denver', country: 'USA', latitude: 39.7392, longitude: -104.9903, bortleClass: 7),
    CityBortleOverride(name: 'Washington DC', country: 'USA', latitude: 38.9072, longitude: -77.0369, bortleClass: 9, radiusKm: 40),
    CityBortleOverride(name: 'Boston', country: 'USA', latitude: 42.3601, longitude: -71.0589, bortleClass: 8, radiusKm: 35),
    CityBortleOverride(name: 'Nashville', country: 'USA', latitude: 36.1627, longitude: -86.7816, bortleClass: 7, radiusKm: 25),
    CityBortleOverride(name: 'Detroit', country: 'USA', latitude: 42.3314, longitude: -83.0458, bortleClass: 8, radiusKm: 35),
    CityBortleOverride(name: 'Portland', country: 'USA', latitude: 45.5152, longitude: -122.6784, bortleClass: 7, radiusKm: 25),
    CityBortleOverride(name: 'Las Vegas', country: 'USA', latitude: 36.1699, longitude: -115.1398, bortleClass: 9, radiusKm: 35),
    CityBortleOverride(name: 'Miami', country: 'USA', latitude: 25.7617, longitude: -80.1918, bortleClass: 8, radiusKm: 35),
    CityBortleOverride(name: 'Atlanta', country: 'USA', latitude: 33.7490, longitude: -84.3880, bortleClass: 8, radiusKm: 40),

    // Canada
    CityBortleOverride(name: 'Toronto', country: 'Canada', latitude: 43.6532, longitude: -79.3832, bortleClass: 8, radiusKm: 40),
    CityBortleOverride(name: 'Montreal', country: 'Canada', latitude: 45.5017, longitude: -73.5673, bortleClass: 8, radiusKm: 35),
    CityBortleOverride(name: 'Vancouver', country: 'Canada', latitude: 49.2827, longitude: -123.1207, bortleClass: 7),
    CityBortleOverride(name: 'Calgary', country: 'Canada', latitude: 51.0447, longitude: -114.0719, bortleClass: 6, radiusKm: 25),
    CityBortleOverride(name: 'Ottawa', country: 'Canada', latitude: 45.4215, longitude: -75.6972, bortleClass: 7, radiusKm: 25),

    // Mexico
    CityBortleOverride(name: 'Mexico City', country: 'Mexico', latitude: 19.4326, longitude: -99.1332, bortleClass: 9, radiusKm: 50),
    CityBortleOverride(name: 'Guadalajara', country: 'Mexico', latitude: 20.6597, longitude: -103.3496, bortleClass: 8),
    CityBortleOverride(name: 'Monterrey', country: 'Mexico', latitude: 25.6866, longitude: -100.3161, bortleClass: 8),

    // ========== SOUTH AMERICA ==========

    // Brazil
    CityBortleOverride(name: 'São Paulo', country: 'Brazil', latitude: -23.5505, longitude: -46.6333, bortleClass: 9, radiusKm: 50),
    CityBortleOverride(name: 'Rio de Janeiro', country: 'Brazil', latitude: -22.9068, longitude: -43.1729, bortleClass: 9, radiusKm: 40),
    CityBortleOverride(name: 'Brasília', country: 'Brazil', latitude: -15.8267, longitude: -47.9218, bortleClass: 7, radiusKm: 25),
    CityBortleOverride(name: 'Salvador', country: 'Brazil', latitude: -12.9714, longitude: -38.5014, bortleClass: 8, radiusKm: 25),
    CityBortleOverride(name: 'Fortaleza', country: 'Brazil', latitude: -3.7172, longitude: -38.5433, bortleClass: 7, radiusKm: 20),
    CityBortleOverride(name: 'Belo Horizonte', country: 'Brazil', latitude: -19.9167, longitude: -43.9345, bortleClass: 8, radiusKm: 25),

    // Argentina
    CityBortleOverride(name: 'Buenos Aires', country: 'Argentina', latitude: -34.6037, longitude: -58.3816, bortleClass: 9, radiusKm: 45),
    CityBortleOverride(name: 'Córdoba', country: 'Argentina', latitude: -31.4201, longitude: -64.1888, bortleClass: 7, radiusKm: 20),
    CityBortleOverride(name: 'Rosario', country: 'Argentina', latitude: -32.9442, longitude: -60.6505, bortleClass: 7, radiusKm: 20),

    // Other South America
    CityBortleOverride(name: 'Lima', country: 'Peru', latitude: -12.0464, longitude: -77.0428, bortleClass: 8, radiusKm: 35),
    CityBortleOverride(name: 'Bogotá', country: 'Colombia', latitude: 4.7110, longitude: -74.0721, bortleClass: 8, radiusKm: 35),
    CityBortleOverride(name: 'Santiago', country: 'Chile', latitude: -33.4489, longitude: -70.6693, bortleClass: 8, radiusKm: 35),
    CityBortleOverride(name: 'Caracas', country: 'Venezuela', latitude: 10.4806, longitude: -66.9036, bortleClass: 8),

    // ========== AFRICA ==========

    CityBortleOverride(name: 'Cairo', country: 'Egypt', latitude: 30.0444, longitude: 31.2357, bortleClass: 9, radiusKm: 40),
    CityBortleOverride(name: 'Lagos', country: 'Nigeria', latitude: 6.5244, longitude: 3.3792, bortleClass: 8, radiusKm: 35),
    CityBortleOverride(name: 'Kinshasa', country: 'DRC', latitude: -4.4419, longitude: 15.2663, bortleClass: 7, radiusKm: 25),
    CityBortleOverride(name: 'Johannesburg', country: 'South Africa', latitude: -26.2041, longitude: 28.0473, bortleClass: 8, radiusKm: 35),
    CityBortleOverride(name: 'Khartoum', country: 'Sudan', latitude: 15.5007, longitude: 32.5599, bortleClass: 7, radiusKm: 20),
    CityBortleOverride(name: 'Alexandria', country: 'Egypt', latitude: 31.2001, longitude: 29.9187, bortleClass: 8, radiusKm: 25),
    CityBortleOverride(name: 'Abidjan', country: 'Ivory Coast', latitude: 5.3600, longitude: -4.0083, bortleClass: 7, radiusKm: 20),
    CityBortleOverride(name: 'Casablanca', country: 'Morocco', latitude: 33.5731, longitude: -7.5898, bortleClass: 7, radiusKm: 25),
    CityBortleOverride(name: 'Nairobi', country: 'Kenya', latitude: -1.2864, longitude: 36.8172, bortleClass: 7, radiusKm: 25),
    CityBortleOverride(name: 'Addis Ababa', country: 'Ethiopia', latitude: 9.0320, longitude: 38.7469, bortleClass: 7, radiusKm: 20),
    CityBortleOverride(name: 'Cape Town', country: 'South Africa', latitude: -33.9249, longitude: 18.4241, bortleClass: 7, radiusKm: 25),
    CityBortleOverride(name: 'Dar es Salaam', country: 'Tanzania', latitude: -6.7924, longitude: 39.2083, bortleClass: 7, radiusKm: 20),

    // ========== OCEANIA ==========

    CityBortleOverride(name: 'Sydney', country: 'Australia', latitude: -33.8688, longitude: 151.2093, bortleClass: 8, radiusKm: 40),
    CityBortleOverride(name: 'Melbourne', country: 'Australia', latitude: -37.8136, longitude: 144.9631, bortleClass: 8, radiusKm: 35),
    CityBortleOverride(name: 'Brisbane', country: 'Australia', latitude: -27.4698, longitude: 153.0251, bortleClass: 7),
    CityBortleOverride(name: 'Perth', country: 'Australia', latitude: -31.9505, longitude: 115.8605, bortleClass: 7, radiusKm: 25),
    CityBortleOverride(name: 'Adelaide', country: 'Australia', latitude: -34.9285, longitude: 138.6007, bortleClass: 6, radiusKm: 20),
    CityBortleOverride(name: 'Auckland', country: 'New Zealand', latitude: -36.8485, longitude: 174.7633, bortleClass: 7, radiusKm: 25),
    CityBortleOverride(name: 'Wellington', country: 'New Zealand', latitude: -41.2865, longitude: 174.7762, bortleClass: 6, radiusKm: 15),
  ];

  /// Find the nearest city override within the specified radius
  /// Returns null if no city is within range
  static CityBortleOverride? findNearestCity(double latitude, double longitude, {double maxDistanceKm = 100.0}) {
    CityBortleOverride? nearest;
    double nearestDistance = double.infinity;

    for (final CityBortleOverride city in cities) {
      final double distance = _calculateDistance(latitude, longitude, city.latitude, city.longitude);

      // Check if within the city's influence radius AND closer than any previous match
      if (distance <= city.radiusKm && distance < nearestDistance) {
        nearest = city;
        nearestDistance = distance;
      }
    }

    return nearest;
  }

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371;

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2));

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }
}
