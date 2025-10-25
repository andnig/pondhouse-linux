#!/bin/bash

# Check if a presentation name was provided
if [ "$#" -ne 1 ]; then
	echo "Usage: $0 <presentation_name>"
	exit 1
fi

# Set the presentation name from the first argument
presentation_name=$1

# Directory where the presentations will be stored
presentations_dir="$HOME/presentations"

# Create the presentations directory if it doesn't exist
if [ ! -d "$presentations_dir" ]; then
	mkdir -p "$presentations_dir"
	echo "Created directory: $presentations_dir"
fi

# Path for the new presentation
presentation_path="$presentations_dir/$presentation_name"

# Clone reveal.js into the presentation subfolder
if [ ! -d "$presentation_path" ]; then
	git clone https://github.com/hakimel/reveal.js.git "$presentation_path"
	echo "reveal.js cloned into $presentation_path"
else
	echo "Directory $presentation_path already exists, skipping clone."
fi

# Move to the presentation directory and run pnpm install
cd "$presentation_path"
pnpm install
pnpm install -D tailwindcss
pnpm dlx tailwindcss init
rm -rf .git
git init --initial-branch=main
echo "Dependencies installed using pnpm."
echo "Add <script src="https://cdn.tailwindcss.com"></script> to the header of your index.html file"
