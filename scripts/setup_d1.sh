#!/bin/bash
set -e

# Setup Cloudflare D1 Data Pipeline
# 1. Checks/Generates zones.db
# 2. Converts to SQL
# 3. Cleans up binary file

# Paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ASSETS_DIR="$PROJECT_ROOT/assets/db"
VENV_DIR="$SCRIPT_DIR/.venv"
ZONES_DB="$ASSETS_DIR/zones.db"
SQL_SCRIPT="$SCRIPT_DIR/export_zones_to_sql.py"
GEN_SCRIPT="$SCRIPT_DIR/generate_zones_vnl.py"

# Activate Venv
if [ -d "$VENV_DIR" ]; then
    source "$VENV_DIR/bin/activate"
else
    echo "Error: Python virtual environment not found in $VENV_DIR"
    exit 1
fi

echo "========================================"
echo "Astr Cloudflare D1 Setup Data Pipeline"
echo "========================================"

# 1. Check if zones.db exists
if [ ! -f "$ZONES_DB" ]; then
    echo "zones.db not found. Generating from VNL data..."
    # Configured for: VNL NPP 2024 Global Configuration Data.tif.gz in project root (../)
    TIF_PATH="$PROJECT_ROOT/VNL NPP 2024 Global Configuration Data.tif.gz"
    
    if [ ! -f "$TIF_PATH" ]; then
        echo "Error: Input TIF file not found at $TIF_PATH"
        exit 1
    fi

    echo "Running generation with input: $TIF_PATH"
    python3 "$GEN_SCRIPT" --tif "$TIF_PATH"
else
    echo "Found existing zones.db"
fi

# 1.5 Validate Coverage
echo "----------------------------------------"
echo "Validating Global Coverage..."
if ! python3 "$SCRIPT_DIR/validate_global_coverage.py"; then
    echo "❌ Validation Failed! Aborting process."
    exit 1
fi

echo "Validation passed. Waiting 5 seconds..."
sleep 5

# 2. Convert to SQL
echo "----------------------------------------"
echo "Converting to SQL..."
python3 "$SQL_SCRIPT" --db "$ZONES_DB" --out "$ASSETS_DIR"

# 3. Cleanup
echo "----------------------------------------"
echo "Cleanup: Removing binary zones.db to save space..."
rm "$ZONES_DB"
echo "Deleted $ZONES_DB"

# 4. Instructions
echo "========================================"
echo "✅ SQL Generation Complete!"
echo "Files are located in: $ASSETS_DIR"
echo ""
echo "To upload to Cloudflare D1, run the following commands (from the project root):"
echo ""

# List all generated SQL files and create wrangler commands
for sql_file in "$ASSETS_DIR"/zones_part*.sql; do
    filename=$(basename "$sql_file")
    echo "npx wrangler d1 execute astr-zones-db --file=assets/db/$filename --remote"
done

echo ""
echo "See docs/cloudflare_d1_setup.md for full details."
