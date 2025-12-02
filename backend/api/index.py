import os
from flask import Flask, jsonify, request
from pymongo import MongoClient
from bson.json_util import dumps
import json

app = Flask(__name__)

# Connect to MongoDB
# Note: In Vercel, env vars are injected.
# We use a global client to take advantage of connection pooling in serverless.
mongo_uri = os.environ.get('MONGODB_URI')
client = None
db = None
collection = None

def get_db():
    global client, db, collection
    if client is None and mongo_uri:
        try:
            client = MongoClient(mongo_uri)
            db = client.get_database('astr')
            collection = db.get_collection('light_pollution')
        except Exception as e:
            print(f"Error connecting to MongoDB: {e}")
            return None
    return collection

@app.route('/')
def home():
    return jsonify({
        "status": "online",
        "service": "Astr Backend",
        "endpoints": ["/api/health", "/api/light-pollution"]
    })

@app.route('/api/health')
def health():
    col = get_db()
    db_status = "connected" if col is not None else "disconnected"
    return jsonify({"status": "ok", "database": db_status})

@app.route('/api/light-pollution')
def get_light_pollution():
    try:
        lat = request.args.get('lat', type=float)
        lon = request.args.get('lon', type=float)

        if lat is None or lon is None:
            return jsonify({"error": "Missing 'lat' or 'lon' parameters"}), 400

        col = get_db()
        if col is None:
            return jsonify({"error": "Database connection failed"}), 500

        # Find nearest point within 50km (50000 meters)
        # MongoDB expects [lon, lat]
        query = {
            "location": {
                "$near": {
                    "$geometry": {
                        "type": "Point",
                        "coordinates": [lon, lat]
                    },
                    "$maxDistance": 50000 
                }
            }
        }

        result = col.find_one(query)

        if result:
            # Convert ObjectId to string for JSON serialization
            result['_id'] = str(result['_id'])
            return jsonify(result)
        else:
            return jsonify({"error": "No data found for this location", "code": "NO_DATA"}), 404

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Vercel requires the app to be exposed as 'app'
if __name__ == '__main__':
    app.run(debug=True)
