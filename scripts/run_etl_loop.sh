#!/bin/bash
# run_etl_loop.sh
# Runs the ETL script in a loop to clear memory/cache after every batch

EXIT_CODE=99

while [ $EXIT_CODE -eq 99 ]; do
    echo "=========================================="
    echo "Starting ETL Batch..."
    echo "=========================================="
    
    # Run script
    source scripts/venv/bin/activate
    python3 scripts/generate_h3_db.py
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 99 ]; then
        echo "Batch complete. Cleaning up and restarting..."
        sleep 2
    elif [ $EXIT_CODE -eq 0 ]; then
        echo "ETL Process Complete!"
        break
    else
        echo "Creation failed with error code $EXIT_CODE"
        exit $EXIT_CODE
    fi
done
