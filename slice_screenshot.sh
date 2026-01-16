#!/bin/bash

# 1. Check if an input file is provided
if [ -z "$1" ]; then
  echo "Error: Please provide an image file."
  echo "Usage: $0 <filename>"
  exit 1
fi

INPUT_FILE="$1"

# 2. Get the width of the image automatically
WIDTH=$(magick identify -format "%w" "$INPUT_FILE")

# 3. Calculate the height for A4 format
# A4 Aspect Ratio is approx 1.4142
RATIO=1.4142
HEIGHT=$(awk -v w="$WIDTH" -v r="$RATIO" 'BEGIN { printf "%.0f", w * r }')

echo "Processing: $INPUT_FILE"
echo "Slicing with dimensions: ${WIDTH}x${HEIGHT}"

# 4. Execute the Magick command
# We use "${INPUT_FILE%.*}" to get the filename without the extension
OUTPUT_NAME="${INPUT_FILE%.*}_part_%d.jpg"

magick "$INPUT_FILE" \
    -crop "${WIDTH}x${HEIGHT}" \
    +repage \
    -extent "${WIDTH}x${HEIGHT}" \
    -reverse \
    "$OUTPUT_NAME"

echo "Done! created slices starting with ${OUTPUT_NAME}"
