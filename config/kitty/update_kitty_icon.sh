#!/bin/bash
# Directory where the png files are located
dir="./icons"
# Destination directory
dest="/usr/share/icons/hicolor"
# Loop through all png files in the directory
for file in "$dir"/*x*.png; do
	# Extract the base name of the file (without path and extension)
	base=$(basename "$file" .png)
	# Extract the number from the file name
	number=$(echo "$base" | grep -o '[0-9]*x[0-9]*')
	# Check if the destination directory exists, if not create it
	if [ ! -d "$dest/$number" ]; then
		mkdir -p "$dest/$number"
	fi
	# Copy the file to the destination directory and rename it to kitty.png
	# If the destination directory does not exist, ignore the error
	cp "$file" "$dest/$number/apps/kitty.png" #2>/dev/null
done
