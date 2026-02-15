import sqlite3

conn = sqlite3.connect('assets/db/temp_zones.sqlite')
c = conn.cursor()

# Check schema
print("Schema:")
c.execute("PRAGMA table_info(zone_data)")
for col in c.fetchall():
    print(col)

# Check for weird types
print("\nChecking for non-REAL ratio_sum:")
c.execute("SELECT h3_index, typeof(ratio_sum), ratio_sum FROM zone_data WHERE typeof(ratio_sum) != 'real' LIMIT 5")
rows = c.fetchall()
if rows:
    for r in rows:
        print(r)
else:
    print("All ratio_sum are REAL")

# Check negative indices
print("\nChecking negative indices:")
c.execute("SELECT h3_index, typeof(ratio_sum), ratio_sum FROM zone_data WHERE h3_index < 0 LIMIT 5")
rows = c.fetchall()
if rows:
    for r in rows:
        print(r)
else:
    print("No negative indices found")

conn.close()
