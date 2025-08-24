#!/bin/bash

# Check if ansible-vault is installed
if ! command -v ansible-vault &>/dev/null; then
  echo "ansible-vault is not installed. Please install it first."
  exit 1
fi

# Check if a folder path and optional --decrypt flag are provided
if [ $# -eq 0 ] || [ $# -gt 2 ]; then
  echo "Usage: $0 /path/to/folder [--decrypt]"
  exit 1
fi

# Set the folder path and check for --decrypt flag
folder_path="$1"
decrypt_mode=false
if [ "$2" = "--decrypt" ]; then
  decrypt_mode=true
fi

# Set the folder path
folder_path="$1"

# Check if the folder exists
if [ ! -d "$folder_path" ]; then
  echo "The specified folder does not exist."
  exit 1
fi

# Create a temporary file for the vault password
temp_password_file=$(mktemp)

# Prompt for the vault password twice and compare
while true; do
  read -s -p "Enter the vault password: " vault_password
  echo
  read -s -p "Confirm the vault password: " vault_password_confirm
  echo

  if [ "$vault_password" = "$vault_password_confirm" ]; then
    echo "$vault_password" >"$temp_password_file"
    break
  else
    echo "Passwords do not match. Please try again."
  fi
done

# Set the vault password file for ansible-vault
export ANSIBLE_VAULT_PASSWORD_FILE="$temp_password_file"

# Find all files in the folder and subfolders and encrypt/decrypt them
find "$folder_path" -type f | while read -r file; do
  if $decrypt_mode; then
    if ansible-vault decrypt "$file" 2>/dev/null; then
      echo "Decrypted: $file"
    else
      echo "Failed to decrypt: $file"
    fi
  else
    if ansible-vault encrypt "$file" 2>/dev/null; then
      echo "Encrypted: $file"
    else
      echo "Failed to encrypt: $file"
    fi
  fi
done

# Clean up the environment variable and remove the temporary password file
unset ANSIBLE_VAULT_PASSWORD_FILE
rm -f "$temp_password_file"

echo "Encryption/Decryption process completed."
