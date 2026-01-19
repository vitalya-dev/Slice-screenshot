#!/bin/bash

# 1. Check if an input file is provided
if [ -z "$1" ]; then
  echo "Error: Please provide an image file."
  echo "Usage: $0 <filename> [format: a4 | a55]"
  exit 1
fi

INPUT_FILE="$1"
FORMAT="${2:-a4}"

# 2. Get Width and TOTAL Height
WIDTH=$(magick identify -format "%w" "$INPUT_FILE")
TOTAL_HEIGHT=$(magick identify -format "%h" "$INPUT_FILE")

# 3. Determine Ratio
case "$FORMAT" in
  "a55") RATIO=1.95 ;;   # Safe height for Galaxy A55
  "a4")  RATIO=1.4142 ;; # Standard A4
  *)     RATIO=1.4142 ;;
esac

# 4. Calculate Slice Height and Overlap
SLICE_HEIGHT=$(awk -v w="$WIDTH" -v r="$RATIO" 'BEGIN { printf "%.0f", w * r }')
OVERLAP=$(awk -v h="$SLICE_HEIGHT" 'BEGIN { printf "%.0f", h * 0.08 }')
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
  
  OUTPUT_NAME="${INPUT_FILE%.*}_${FORMAT}_part_$(printf "%02d" $COUNTER).jpg"
  
  # Initialize empty array for drawing arguments
  DRAW_ARGS=()

  # Only add drawing commands if this is NOT the first page (Counter > 0)
  if [ $COUNTER -gt 0 ]; then
      # Add the gray tint rectangle ONLY
      DRAW_ARGS+=(-fill "rgba(0,0,0,0.1)")
      DRAW_ARGS+=(-draw "rectangle 0,0 $WIDTH,$OVERLAP")
  fi

  # Execute Magick
  magick "$INPUT_FILE" \
    -crop "${WIDTH}x${SLICE_HEIGHT}+0+${CURRENT_Y}" \
    +repage \
    -background white \
    -gravity North \
    -extent "${WIDTH}x${SLICE_HEIGHT}" \
    "${DRAW_ARGS[@]}" \
    "$OUTPUT_NAME"

  echo "Created: $OUTPUT_NAME"

  CURRENT_Y=$((CURRENT_Y + STEP))
  COUNTER=$((COUNTER + 1))

done

echo "----------------"
echo "Reordering timestamps..."

# 6. FORCE timestamps (The Sort Fix)
for (( i=0; i<COUNTER; i++ )); do
   TARGET_FILE="${INPUT_FILE%.*}_${FORMAT}_part_$(printf "%02d" $i).jpg"
   
   if date --version >/dev/null 2>&1; then
       # Linux
       touch -d "$i seconds ago" "$TARGET_FILE"
   else
       # macOS
       touch -A -$(printf "%02d" $i) "$TARGET_FILE"
   fi
done

echo "Done! 'Part_00' is the newest. Overlap areas are marked with gray."