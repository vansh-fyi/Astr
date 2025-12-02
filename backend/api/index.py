from flask import Flask, request, jsonify
import os
import sys
from dotenv import load_dotenv
from pymongo import MongoClient
from pymongo.errors import ConnectionFailure
import math

# Load environment variables
load_dotenv()

app = Flask(__name__)

# Global error handler
@app.errorhandler(Exception)
def handle_exception(e):
    """Global exception handler for all unhandled errors"""
    import traceback
    error_trace = traceback.format_exc()
    print(f"Unhandled error: {error_trace}", file=sys.stderr)
    return jsonify({
        "error": "Internal server error",
        "message": str(e),
        "type": type(e).__name__
    }), 500

# MongoDB connection
MONGO_URI = os.getenv('MONGODB_URI')
mongo_client = None
db = None

def get_db():
    """Initialize MongoDB connection lazily"""
    global mongo_client, db
    if mongo_client is None:
        if not MONGO_URI:
            print("Warning: MONGODB_URI environment variable not set", file=sys.stderr)
            return None
        try:
            print(f"Attempting MongoDB connection...", file=sys.stderr)
            mongo_client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
            # Test connection
            mongo_client.admin.command('ping')
            db = mongo_client.get_database()
            print("MongoDB connected successfully", file=sys.stderr)
            return db
        except (ConnectionFailure, Exception) as e:
            print(f"MongoDB connection failed: {e}", file=sys.stderr)
            mongo_client = None
            db = None
            return None
    return db

def calculate_bortle_class(mpsas):
    """
    Convert MPSAS to Bortle Dark Sky Scale
    MPSAS ranges from ~22 (darkest) to ~12 (brightest)
    """
    if mpsas >= 21.7:
        return 1  # Excellent dark sky
    elif mpsas >= 21.5:
        return 2  # Typical dark sky
    elif mpsas >= 21.3:
        return 3  # Rural sky
    elif mpsas >= 20.4:
        return 4  # Rural/suburban transition
    elif mpsas >= 19.1:
        return 5  # Suburban sky
    elif mpsas >= 18.0:
        return 6  # Bright suburban sky
    elif mpsas >= 18.0:
        return 7  # Suburban/urban transition
    elif mpsas >= 17.0:
        return 8  # City sky
    else:
        return 9  # Inner city sky

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    db = get_db()
    db_status = "connected" if db is not None else "disconnected"

    return jsonify({
        "status": "healthy",
        "service": "Astr Backend API",
        "database": db_status
    }), 200

@app.route('/api/light-pollution', methods=['GET'])
def get_light_pollution():
    """
    Get light pollution data for given coordinates
    Query params: lat (latitude), lon (longitude)
    Returns: MPSAS value and Bortle class
    """
    # Validate query parameters
    lat = request.args.get('lat', type=float)
    lon = request.args.get('lon', type=float)

    if lat is None or lon is None:
        return jsonify({
            "error": "Missing required parameters",
            "message": "Both 'lat' and 'lon' query parameters are required"
        }), 400

    # Validate coordinate ranges
    if not (-90 <= lat <= 90):
        return jsonify({
            "error": "Invalid latitude",
            "message": "Latitude must be between -90 and 90"
        }), 400

    if not (-180 <= lon <= 180):
        return jsonify({
            "error": "Invalid longitude",
            "message": "Longitude must be between -180 and 180"
        }), 400

    # Get database connection
    db = get_db()
    if db is None:
        return jsonify({
            "error": "Database unavailable",
            "message": "Unable to connect to MongoDB. Using fallback data.",
            "lat": lat,
            "lon": lon,
            "mpsas": 18.5,
            "bortle_class": 6,
            "fallback": True
        }), 200

    # Query MongoDB for nearest light pollution data
    try:
        collection = db.light_pollution

        # Use geospatial query to find nearest point
        # MongoDB 2dsphere index query
        result = collection.find_one({
            "location": {
                "$near": {
                    "$geometry": {
                        "type": "Point",
                        "coordinates": [lon, lat]  # GeoJSON uses [lon, lat] order
                    },
                    "$maxDistance": 50000  # 50km radius
                }
            }
        })

        if result:
            mpsas = result.get('mpsas', 18.5)
            bortle = calculate_bortle_class(mpsas)

            return jsonify({
                "lat": lat,
                "lon": lon,
                "mpsas": round(mpsas, 2),
                "bortle_class": bortle,
                "fallback": False
            }), 200
        else:
            # No data found, return fallback
            return jsonify({
                "error": "No data found",
                "message": "No light pollution data found within 50km of the given coordinates. Using fallback data.",
                "lat": lat,
                "lon": lon,
                "mpsas": 18.5,
                "bortle_class": 6,
                "fallback": True
            }), 200

    except Exception as e:
        print(f"Query error: {e}")
        return jsonify({
            "error": "Query failed",
            "message": str(e),
            "lat": lat,
            "lon": lon,
            "mpsas": 18.5,
            "bortle_class": 6,
            "fallback": True
        }), 200

@app.route('/', methods=['GET'])
def root():
    """Root endpoint"""
    return jsonify({
        "message": "Astr Backend API",
        "version": "1.0.0",
        "endpoints": {
            "/api/health": "Health check",
            "/api/light-pollution": "Get light pollution data (requires lat and lon query params)"
        }
    }), 200

# For local development
if __name__ == '__main__':
    app.run(debug=True, port=5000)
