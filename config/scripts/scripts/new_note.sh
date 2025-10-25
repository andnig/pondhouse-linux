#!/bin/bash

# Function to display usage information
usage() {
	echo "Usage: $0 IDEA_TYPE FILE_NAME"
	echo "IDEA_TYPE: The type of idea. Can be 'idea', 'russmedia', or 'general'."
	echo "FILE_NAME: The name of the file to create."
}

# Check if at least one argument is provided
if [ $# -lt 2 ]; then
	usage
	exit 1
fi

# Assign arguments
IDEA_TYPE="$1"
FILE_NAME="$2"

# Check if the provided idea type is valid
if [ "$IDEA_TYPE" != "idea" ] && [ "$IDEA_TYPE" != "russmedia" ] && [ "$IDEA_TYPE" != "general" ]; then
	echo "Invalid idea type. Can be 'idea', 'russmedia', or 'general'."
	exit 1
fi

if [ "$IDEA_TYPE" == "idea" ]; then
	IDEA_TYPE="ideas"
fi

# Create the file
touch "$HOME/.notes/reference/$IDEA_TYPE/$FILE_NAME"

# Open the file in nvim
cd $HOME/.notes/reference/$IDEA_TYPE && nvim "$HOME/.notes/reference/$IDEA_TYPE/$FILE_NAME.md"
