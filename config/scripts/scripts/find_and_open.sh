#!/bin/bash

# Function to display usage information
usage() {
  echo "Usage: $0 SEARCH_TERM [OPEN_PROGRAM] [--folder=SEARCH_FOLDER]"
  echo "SEARCH_TERM: The term to search for."
  echo "OPEN_PROGRAM: The program to open the file with. Default is batcat, bat, or cat."
  echo "SEARCH_FOLDER: The folder to search in. Default is ~/.notes. Specify with --folder"
}

# Check if at least one argument is provided
if [ $# -lt 1 ]; then
  usage
  exit 1
fi

# Assign first argument
SEARCH_TERM="$1"
shift # Shift after capturing the search term to process the rest arguments

# Initialize default program
OPEN_PROGRAM="$(command -v batcat || command -v bat || echo cat)"

# Default search folder
SEARCH_FOLDER="$HOME/.notes"

# Process remaining arguments
while (("$#")); do
  case $1 in
  --folder=*)
    SEARCH_FOLDER="${1#*=}"
    shift
    ;;
  *)
    # If it's not the folder option, it must be the OPEN_PROGRAM
    OPEN_PROGRAM="$1"
    shift
    ;;
  esac
done

# Search for the provided term in the specified folder and open the selected file with the specified program
rg -uu "$SEARCH_TERM" "$SEARCH_FOLDER" --files-with-matches | fzf --preview 'bat --style=numbers --color=always --line-range :500 {}' | cut -d':' -f1 | xargs -I '{}' "$OPEN_PROGRAM" '{}'
