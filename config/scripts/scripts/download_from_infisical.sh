#!/bin/bash

# Function to display help message
show_help() {
  cat <<EOF
Usage: $(basename "$0") [--project-id PROJECT_ID] <environment> [output_file]

Export environment variables from Infisical to a .env file.

Arguments:
    environment      Source environment in Infisical (e.g., dev, prod, staging)
    output_file      Optional path to the output .env file (defaults to .env in current directory)

Options:
    --project-id     Optional project ID to specify the source Infisical project

Examples:
    $(basename "$0") production
    $(basename "$0") production /path/to/.env
    $(basename "$0") --project-id abc123 production /path/to/.env

Notes:
    - The output file will be created or overwritten
    - Requires Infisical CLI to be installed and configured
    - If no output file is specified, .env in the current directory will be used

EOF
}

# Initialize variables
PROJECT_ID=""
ENV=""
OUTPUT_FILE=".env"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    --project-id)
      if [ -z "$2" ]; then
        echo "Error: --project-id requires a value"
        echo "Try '$(basename "$0") --help' for more information"
        exit 1
      fi
      PROJECT_ID="$2"
      shift 2
      ;;
    *)
      # Positional arguments
      if [ -z "$ENV" ]; then
        ENV="$1"
      elif [ -z "$2" ] || [[ "$2" == --* ]]; then
        OUTPUT_FILE="$1"
      else
        OUTPUT_FILE="$1"
      fi
      shift
      ;;
  esac
done

# Check if required arguments are provided
if [ -z "$ENV" ]; then
  echo "Error: Environment is required"
  echo "Try '$(basename "$0") --help' for more information"
  exit 1
fi

# Check if the output directory exists and is writable
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
if [ ! -d "$OUTPUT_DIR" ]; then
  echo "Error: Directory does not exist: $OUTPUT_DIR"
  exit 1
fi

if [ ! -w "$OUTPUT_DIR" ]; then
  echo "Error: Cannot write to directory: $OUTPUT_DIR"
  exit 1
fi

# Export secrets from Infisical
echo "Downloading secrets from Infisical environment: $ENV"
if [ -n "$PROJECT_ID" ]; then
  echo "Using project ID: $PROJECT_ID"
  infisical export --env "$ENV" --projectId "$PROJECT_ID" > "$OUTPUT_FILE"
else
  infisical export --env "$ENV" > "$OUTPUT_FILE"
fi

# Check if the export was successful
if [ $? -eq 0 ]; then
  echo "Successfully exported secrets to $OUTPUT_FILE"
  echo "File contains $(grep -c "^[^#]" "$OUTPUT_FILE" 2>/dev/null || echo 0) environment variables"
else
  echo "Error: Failed to export secrets from Infisical"
  # Clean up empty file if created
  if [ -f "$OUTPUT_FILE" ] && [ ! -s "$OUTPUT_FILE" ]; then
    rm "$OUTPUT_FILE"
  fi
  exit 1
fi