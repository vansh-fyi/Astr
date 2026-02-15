import h3
import sqlite3
import struct
import os

print(f"H3 Version: {h3.__version__}")

# Check output of latlng_to_cell
lat, lon = 40.7, -74.0
h3_out = h3.latlng_to_cell(lat, lon, 8)
print(f"latlng_to_cell gives: {h3_out} (type: {type(h3_out)})")

if isinstance(h3_out, str):
    h3_int = int(h3_out, 16)
    print(f"As int: {h3_int}")
    
    # Check signed conversion
    try:
        h3_signed = struct.unpack('q', struct.pack('Q', h3_int))[0]
        print(f"As signed 64-bit: {h3_signed}")
        
        # Back to unsigned
        h3_unsigned = struct.unpack('Q', struct.pack('q', h3_signed))[0]
        print(f"Back to unsigned: {h3_unsigned}")
        assert h3_int == h3_unsigned
        print("Roundtrip successful")
        
        # Try sqlite insert
        db_path = "test_sqlite_int.db"
        if os.path.exists(db_path): os.remove(db_path)
        
        conn = sqlite3.connect(db_path)
        conn.execute("CREATE TABLE t (id INTEGER PRIMARY KEY)")
        try:
            conn.execute("INSERT INTO t VALUES (?)", (h3_signed,))
            conn.commit()
            print("Successfully inserted signed int into SQLite INTEGER PRIMARY KEY")
            
            # Read back
            cur = conn.execute("SELECT id FROM t")
            val = cur.fetchone()[0]
            print(f"Read back from SQLite: {val}")
            assert val == h3_signed
            print("SQLite Read/Write verified")
            
        except Exception as e:
            print(f"SQLite error: {e}")
        finally:
            conn.close()
            if os.path.exists(db_path): os.remove(db_path)
            
    except Exception as e:
        print(f"Conversion error: {e}")
