#!/bin/bash

# 1. Check if an input file is provided
if [ -z "$1" ]; then
  echo "Error: Please provide an image file."
  echo "Usage: $0 <filename> [format: a4 | a55]"
  exit 1
fi

INPUT_FILE="$1"
FORMAT="${2:-a4}"

# 2. Get Width and TOTAL Height of the original image
WIDTH=$(magick identify -format "%w" "$INPUT_FILE")
TOTAL_HEIGHT=$(magick identify -format "%h" "$INPUT_FILE")

# 3. Determine Ratio based on format
case "$FORMAT" in
  "a55")
    RATIO=1.95   # Safe height for Galaxy A55
    ;;
  "a4")
    RATIO=1.4142 # Standard A4
    ;;
  *)
    RATIO=1.4142
    ;;
esac

# 4. Calculate Slice Height and Overlap
# SLICE_HEIGHT: Width * Ratio
SLICE_HEIGHT=$(awk -v w="$WIDTH" -v r="$RATIO" 'BEGIN { printf "%.0f", w * r }')

# OVERLAP: We set this to roughly 8% of the slice height (approx 150-200px)
OVERLAP=$(awk -v h="$SLICE_HEIGHT" 'BEGIN { printf "%.0f", h * 0.08 }')

# STEP: How much we move down (Height - Overlap)
STEP=$((SLICE_HEIGHT - OVERLAP))

echo "--- Settings ---"
echo "Format: $FORMAT"
echo "Slice Height: $SLICE_HEIGHT px"
echo "Overlap: $OVERLAP px"
echo "----------------"

# 5. The Slicing Loop
CURRENT_Y=0
COUNTER=0

while [ $CURRENT_Y -lt $TOTAL_HEIGHT ]; do
  
  # Naming: image_a55_part_00.jpg, _01.jpg, etc.
  OUTPUT_NAME="${INPUT_FILE%.*}_${FORMAT}_part_$(printf "%02d" $COUNTER).jpg"
  
  # MAGICK COMMAND EXPLAINED:
  # 1. -crop: Cut the specific piece at the current Y position.
  # 2. +repage: Reset the canvas logic so it doesn't "remember" it was part of a big image.
  # 3. -background white: Set the fill color to white.
  # 4. -gravity North: Pin the image to the TOP (so white space goes to the bottom).
  # 5. -extent: Force the canvas to be the full calculated size.
  
  magick "$INPUT_FILE" \
    -crop "${WIDTH}x${SLICE_HEIGHT}+0+${CURRENT_Y}" \
    +repage \
    -background white \
    -gravity North \
    -extent "${WIDTH}x${SLICE_HEIGHT}" \
    "$OUTPUT_NAME"

  echo "Created: $OUTPUT_NAME (Offset: $CURRENT_Y)"

  # Move the window down
  CURRENT_Y=$((CURRENT_Y + STEP))
  COUNTER=$((COUNTER + 1))

done

echo "Done! Generated $COUNTER images."