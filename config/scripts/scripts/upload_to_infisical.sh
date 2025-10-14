#!/bin/bash

set_secrets_batch_with_retry() {
  local env="$1"
  local project_id="$2"
  shift 2
  local secrets=("$@")
  local max_retries=5
  local retry_count=0
  local wait_time=60

  while [ $retry_count -lt $max_retries ]; do
    local output
    local exit_code
    
    if [ -n "$project_id" ]; then
      output=$(infisical secrets set "${secrets[@]}" --env "$env" --projectId "$project_id" 2>&1)
      exit_code=$?
    else
      output=$(infisical secrets set "${secrets[@]}" --env "$env" 2>&1)
      exit_code=$?
    fi

    if [ $exit_code -eq 0 ]; then
      return 0
    fi

    if echo "$output" | grep -qi "rate limit\|too many requests\|429"; then
      retry_count=$((retry_count + 1))
      if [ $retry_count -lt $max_retries ]; then
        echo "Rate limited. Waiting ${wait_time}s before retry $retry_count/$max_retries"
        sleep $wait_time
      else
        echo "Error: Max retries reached"
        echo "$output"
        return 1
      fi
    else
      echo "Error setting secrets: $output"
      return 1
    fi
  done

  return 1
}

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

secrets=()

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

    if [ -z "$value" ]; then
      echo "Skipping empty value for key: $key"
      continue
    fi

    secrets+=("$key=$value")
  fi
done <"$ENV_FILE"

if [ ${#secrets[@]} -eq 0 ]; then
  echo "No secrets to upload"
  exit 0
fi

echo "Uploading ${#secrets[@]} secrets..."
set_secrets_batch_with_retry "$ENV" "$PROJECT_ID" "${secrets[@]}"

if [ $? -eq 0 ]; then
  echo "Successfully processed $ENV_FILE for environment $ENV"
else
  echo "Failed to upload secrets"
  exit 1
fi
