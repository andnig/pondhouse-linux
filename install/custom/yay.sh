#!/bin/bash

# Array of packages to install
packages=(
  "google-cloud-cli"
  "google-cloud-cli-bq"
  "google-cloud-cli-component-gke-gcloud-auth-plugin"
  "fpp"
  "infisical-bin"
  "clipse-bin"
  "zen-browser-bin"
  "stripe-cli"
  "sunshine"
  "ttf-ms-win11-auto"
  "tlrc"
)

# Configuration
MAX_RETRIES=5
RETRY_DELAY=20

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to install a single package with retry logic
install_package() {
  local package="$1"
  local attempt=1

  echo -e "${YELLOW}Installing package: $package${NC}"

  while [ $attempt -le $MAX_RETRIES ]; do
    echo "  Attempt $attempt of $MAX_RETRIES..."

    # Run yay and capture output and exit code
    output=$(yay -S --needed --noconfirm "$package" 2>&1)
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
      echo -e "${GREEN}  ✓ Successfully installed: $package${NC}"
      return 0
    fi

    # Check if the error is rate limiting (429)
    if echo "$output" | grep -q "429\|rate limit\|Too Many Requests"; then
      echo -e "${YELLOW}  Rate limit detected (429). Waiting ${RETRY_DELAY} seconds before retry...${NC}"
      sleep $RETRY_DELAY
    else
      # For other errors, still wait but with a shorter delay
      echo -e "${RED}  Failed to install $package (exit code: $exit_code)${NC}"
      if [ $attempt -lt $MAX_RETRIES ]; then
        echo "  Waiting 5 seconds before retry..."
        sleep 5
      fi
    fi

    attempt=$((attempt + 1))
  done

  echo -e "${RED}  ✗ Failed to install $package after $MAX_RETRIES attempts${NC}"
  return 1
}

# Main execution
echo "Starting AUR package installation..."
echo "Packages to install: ${#packages[@]}"
echo "Max retries per package: $MAX_RETRIES"
echo "Rate limit retry delay: ${RETRY_DELAY}s"
echo "----------------------------------------"

failed_packages=()
successful_packages=()

for package in "${packages[@]}"; do
  if install_package "$package"; then
    successful_packages+=("$package")
  else
    failed_packages+=("$package")
  fi

  # Add a small delay between packages to avoid rate limiting
  if [ "$package" != "${packages[-1]}" ]; then
    echo "  Waiting 5 seconds before next package..."
    sleep 5
  fi
  echo "----------------------------------------"
done

# Summary
echo
echo "Installation Summary:"
echo "===================="
echo -e "${GREEN}Successfully installed (${#successful_packages[@]}):${NC}"
for pkg in "${successful_packages[@]}"; do
  echo "  ✓ $pkg"
done

if [ ${#failed_packages[@]} -gt 0 ]; then
  echo
  echo -e "${RED}Failed to install (${#failed_packages[@]}):${NC}"
  for pkg in "${failed_packages[@]}"; do
    echo "  ✗ $pkg"
  done
fi

# Always exit with 0 to prevent parent script from failing
echo
echo "Script completed. Exiting with success code (0) regardless of installation results."
exit 0
