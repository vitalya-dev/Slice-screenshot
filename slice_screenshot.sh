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
  
  magick "$INPUT_FILE" \
    -crop "${WIDTH}x${SLICE_HEIGHT}+0+${CURRENT_Y}" \
    +repage \
    -background white \
    -gravity North \
    -extent "${WIDTH}x${SLICE_HEIGHT}" \
    "$OUTPUT_NAME"

  echo "Created: $OUTPUT_NAME"

  CURRENT_Y=$((CURRENT_Y + STEP))
  COUNTER=$((COUNTER + 1))

done

echo "----------------"
echo "Reordering timestamps..."

# 6. FORCE timestamps (New Logic)
# We loop through the files we just made (0 to COUNTER-1).
# We set Part 00 to "Now".
# We set Part 01 to "1 second ago", etc.
# This forces the OS to see Part 00 as the absolute newest.

for (( i=0; i<COUNTER; i++ )); do
   TARGET_FILE="${INPUT_FILE%.*}_${FORMAT}_part_$(printf "%02d" $i).jpg"
   
   # Use 'touch -d' to subtract seconds from NOW. 
   # Example: Part 03 gets touched with time "3 seconds ago"
   # macOS/BSD use different syntax than Linux, so we handle both.
   
   if date --version >/dev/null 2>&1; then
       # Linux (GNU) syntax
       touch -d "$i seconds ago" "$TARGET_FILE"
   else
       # macOS (BSD) syntax
       # -A adjusts time by -SS seconds
       touch -A -$(printf "%02d" $i) "$TARGET_FILE"
   fi
   
   echo "Updated time for $TARGET_FILE (Minus $i seconds)"
done

echo "Done! 'Part_00' is now guaranteed to be the most recent."