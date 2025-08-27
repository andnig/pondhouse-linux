#!/bin/bash

# Array of packages to install
packages=(
  "google-cloud-cli"
  "google-cloud-cli-bq"
  "google-cloud-cli-component-gke-gcloud-auth-plugin"
  "tlrc"
  "fpp"
  "infisical-bin"
  "clipse-bin"
  "zen-browser-bin"
  "stripe-cli"
  "sunshine"
  "ttf-ms-win11-auto"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to install a single package from GitHub AUR repository
install_package() {
  local package="$1"
  local tmpdir="/tmp/aur-install-$$-$package"
  
  echo -e "${YELLOW}Installing package: $package${NC}"
  
  # Create temporary directory
  mkdir -p "$tmpdir"
  cd "$tmpdir" || {
    echo -e "${RED}  Failed to create temporary directory${NC}"
    rm -rf "$tmpdir"
    return 1
  }
  
  # Clone the package from AUR repository
  if git clone --branch "$package" --single-branch https://github.com/archlinux/aur.git "$package" 2>/dev/null; then
    cd "$package" || {
      echo -e "${RED}  Failed to enter package directory${NC}"
      cd /
      rm -rf "$tmpdir"
      return 1
    }
    
    # Build and install the package
    if makepkg -si --noconfirm 2>&1; then
      echo -e "${GREEN}  ✓ Successfully installed $package${NC}"
      cd /
      rm -rf "$tmpdir"
      return 0
    else
      echo -e "${RED}  Failed to build/install $package${NC}"
    fi
  else
    echo -e "${RED}  Failed to clone $package from GitHub AUR repository${NC}"
  fi
  
  # Cleanup
  cd /
  rm -rf "$tmpdir"
  return 1
}

# Main execution
echo "Starting AUR package installation from GitHub..."
echo "Packages to install: ${#packages[@]}"
echo "----------------------------------------"

failed_packages=()
successful_packages=()

for package in "${packages[@]}"; do
  if install_package "$package"; then
    successful_packages+=("$package")
  else
    failed_packages+=("$package")
    echo -e "${YELLOW}  Skipping failed package and continuing...${NC}"
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
