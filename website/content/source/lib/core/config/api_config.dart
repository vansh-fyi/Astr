class ApiConfig {
  // ---------------------------------------------------------------------------
  // ENVIRONMENT CONFIGURATION
  // ---------------------------------------------------------------------------
  
  // Feature Flag: Switch to true to force proxy usage (future proofing)
  // AC 1: Hybrid API Configuration - Switch
  static const bool useProxy = false;

  // 1. PROXIED ENDPOINTS (Cloudflare Worker)
  //    Use this for the live app or when keys are required.
  static const String _proxyBaseUrl = 'https://astr-proxy.astr-vansh-fyi.workers.dev/api';
  
  // 2. DIRECT ENDPOINTS (Open-Meteo Exception)
  //    AC 2: Open-Meteo Direct Client (The Exception)
  //    Safe to use directly because Open-Meteo is keyless and free for non-commercial use.
  static const String _directWeatherBaseUrl = 'https://api.open-meteo.com/v1';
  static const String _directGeocodingBaseUrl = 'https://geocoding-api.open-meteo.com/v1';

  // Dynamic Getters
  static String get weatherBaseUrl => useProxy ? '$_proxyBaseUrl/weather' : _directWeatherBaseUrl;
  static String get geocodingBaseUrl => useProxy ? '$_proxyBaseUrl/geocode' : _directGeocodingBaseUrl;
  
  // ---------------------------------------------------------------------------
}
