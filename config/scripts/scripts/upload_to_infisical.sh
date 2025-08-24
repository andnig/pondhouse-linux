#!/bin/bash

# Function to display help message
show_help() {
  cat <<EOF
Usage: $(basename "$0") [--project-id PROJECT_ID] <env_file_path> <environment>

Import environment variables from a .env file to Infisical.

Arguments:
    env_file_path    Path to the .env file containing the variables
    environment      Target environment in Infisical (e.g., dev, prod, staging)

Options:
    --project-id     Optional project ID to specify the target Infisical project

Examples:
    $(basename "$0") /path/to/.env production
    $(basename "$0") --project-id abc123 /path/to/.env production

Notes:
    - The .env file should contain variables in KEY=VALUE format
    - Empty lines and lines starting with # are ignored
    - Requires Infisical CLI to be installed and configured

EOF
}

# Initialize variables
PROJECT_ID=""
ENV_FILE=""
ENV=""

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
      if [ -z "$ENV_FILE" ]; then
        ENV_FILE="$1"
      elif [ -z "$ENV" ]; then
        ENV="$1"
      else
        echo "Error: Too many arguments"
        echo "Try '$(basename "$0") --help' for more information"
        exit 1
      fi
      shift
      ;;
  esac
done

# Check if required arguments are provided
if [ -z "$ENV_FILE" ] || [ -z "$ENV" ]; then
  echo "Error: Both env_file_path and environment are required"
  echo "Try '$(basename "$0") --help' for more information"
  exit 1
fi

# Check if the file exists
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: File not found: $ENV_FILE"
  exit 1
fi

# Check if the file is readable
if [ ! -r "$ENV_FILE" ]; then
  echo "Error: Cannot read file: $ENV_FILE"
  exit 1
fi

# Read each line in the .env file
while IFS= read -r line || [ -n "$line" ]; do
  # Skip empty lines and lines starting with '#'
  if [ -n "$line" ] && [ "${line:0:1}" != "#" ]; then
    # Split the line into key and value
    key=$(echo "$line" | cut -d= -f1)
    value=$(echo "$line" | cut -d= -f2-)

    # Strip quotes if value starts and ends with either '' or ""
    if [[ ($value == \"*\" || $value == \'*\') ]]; then
      # Remove the first and last character (quotes)
      value="${value:1:${#value}-2}"
    fi

    # Set the secret in Infisical with the potentially modified value
    if [ -n "$PROJECT_ID" ]; then
      infisical secrets set "$key=$value" --env "$ENV" --projectId "$PROJECT_ID"
    else
      infisical secrets set "$key=$value" --env "$ENV"
    fi
  fi
done <"$ENV_FILE"

echo "Successfully processed $ENV_FILE for environment $ENV"
