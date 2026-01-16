#!/bin/bash

# 1. Check if an input file is provided
if [ -z "$1" ]; then
  echo "Error: Please provide an image file."
  echo "Usage: $0 <filename>"
  exit 1
fi

INPUT_FILE="$1"

# 2. Get the width of the image automatically
# We use 'identify -format "%w"' to extract just the width number
WIDTH=$(magick identify -format "%w" "$INPUT_FILE")

echo "Input File: $INPUT_FILE"
echo "Detected Width: $WIDTH pixels"
