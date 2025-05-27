#!/bin/bash

# Input and output files
DATA_FILE="data.txt"
OUTPUT_FILE="new.txt"

# Clear output file if it exists
> "$OUTPUT_FILE"

# Read data file in blocks
while IFS= read -r line; do
    if [[ $line =~ ^## (.*) ]]; then
        version="${BASH_REMATCH[1]}"
        echo "## $version" >> "$OUTPUT_FILE"
        urls=()
        for i in {1..3}; do
            IFS= read -r url
            urls+=($url)
        done

        for url in "${urls[@]}"; do
            filename="$(basename "$url")"
            if wget -q -O "$filename" "$url"; then
                sha512sum="$(sha512sum "$filename" | awk '{print $1}')"
                echo "$url $filename" >> "$OUTPUT_FILE"
                echo "sha512:$sha512sum" >> "$OUTPUT_FILE"
            else
                echo "$url download failed" >> "$OUTPUT_FILE"
            fi
        done
    fi
done < "$DATA_FILE"

# Clean up downloaded files
rm -f "$filename"
