#!/bin/bash

# Check if the correct number of arguments was provided
if [ "$#" -ne 3 ]; then
	echo "Usage: $0 <input_file.md> <output_file.html> <theme>"
	exit 1
fi

# Assign variables based on user input
input_file=$1
output_file=$2
theme=$3

# Check if the input file exists
if [ ! -f "$input_file" ]; then
	echo "Error: Input file does not exist."
	exit 1
fi

# Determine the directory of the input file
input_dir=$(dirname "$input_file")

# Check if slides.css exists in the same directory as the input file
include_css="--include-in-header=$input_dir/slides.css"
if [ ! -f "$input_dir/slides.css" ]; then
	echo "No slides.css found in $input_dir, proceeding without custom CSS."
	include_css=""
fi

# Run pandoc command with specified parameters
pandoc -t revealjs -s -o "$output_file" "$input_file" -V revealjs-url=https://unpkg.com/reveal.js/ $include_css -V theme="$theme"
echo "Presentation generated: $output_file"
