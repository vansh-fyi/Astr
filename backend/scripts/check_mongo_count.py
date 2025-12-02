import os
import sys
from dotenv import load_dotenv
from pymongo import MongoClient

# Load environment variables
load_dotenv(os.path.join(os.path.dirname(__file__), '../.env'))

def check_count():
    uri = os.getenv('MONGODB_URI')
    if not uri:
        print("Error: MONGODB_URI not found.")
        sys.exit(1)
    
    try:
        client = MongoClient(uri)
        db = client.get_database('astr')
        collection = db.get_collection('light_pollution')
        
        count = collection.count_documents({})
        print(f"Total documents in 'light_pollution': {count}")
        
        # Optional: Check for a specific tile to see if it exists
        # sample = collection.find_one()
        # if sample:
        #     print("Sample document:", sample.get('tile_id', 'Unknown'))
            
    except Exception as e:
        print(f"Error connecting to MongoDB: {e}")
        sys.exit(1)

if __name__ == "__main__":
    check_count()
