#!/bin/bash

# Check if list.txt exists
if [[ ! -f list.txt ]]; then
    echo "Error: list.txt not found!"
    exit 1
fi

# Create output directory
OUTPUT_DIR="lighthouse_reports"
mkdir -p "$OUTPUT_DIR"

# Read each URL from list.txt and run Lighthouse
while IFS= read -r url; do
    if [[ -n "$url" ]]; then
        TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
        DOMAIN=$(echo "$url" | awk -F/ '{print $3}')
        OUTPUT_FILE="$OUTPUT_DIR/${DOMAIN}_${TIMESTAMP}.report.html"
        
        echo "Running Lighthouse for: $url"
        lighthouse "$url" \
            --form-factor=desktop \
            --screenEmulation.disabled \
            --chrome-flags="--no-sandbox --disable-gpu --incognito --user-data-dir=/tmp/lighthouse" \
            --throttling-method=provided \
            --output html \
            --output-path "$OUTPUT_FILE" \
            --view
    fi
done < list.txt

echo "Lighthouse audits completed. Reports are saved in $OUTPUT_DIR"