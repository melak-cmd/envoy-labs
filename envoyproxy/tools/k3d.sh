#!/bin/bash

# This script installs, updates, or uninstalls the k3d tool, a lightweight Kubernetes distribution.

# Colors for messages
GREEN='\033[0;32m'   # Green color
YELLOW='\033[1;33m'  # Yellow color
RED='\033[0;31m'     # Red color
NC='\033[0m'         # No color

# Function to display colored messages
color_message() {
  local color="$1"
  local message="$2"
  echo -e "${color}${message}${NC}"
}

# Global Variables
K3D_REPO_URL="https://github.com/k3d-io/k3d"
LATEST_RELEASE_URL="$K3D_REPO_URL/releases/latest"

# Function to check if k3d is already installed and its version matches the desired version
check_installed_k3d_version() {
  local installed_version
  installed_version=$(k3d version 2>/dev/null | grep 'k3d version' | awk '{print $3}' | sed 's/v//')
  
  if [[ "$installed_version" == "$K3D_TAG" ]]; then
    color_message "${GREEN}" "k3d $K3D_TAG is already installed."
    return 0
  else
    color_message "${YELLOW}" "k3d $K3D_TAG is available. Changing from version $installed_version."
    return 1
  fi
}

# Function to install or update k3d
install_or_update_k3d() {
  local k3d_dist="k3d-$K3D_OS-$K3D_ARCH"
  local download_url="$K3D_REPO_URL/releases/download/v$K3D_TAG/$k3d_dist"

  if ! check_installed_k3d_version; then
    color_message "${YELLOW}" "Downloading k3d $K3D_TAG..."
    wget -q --show-progress -c "$download_url" -O "$k3d_dist"
    chmod +x "$k3d_dist"
    sudo mv "$k3d_dist" "/usr/local/bin/k3d"
    color_message "${GREEN}" "k3d $K3D_TAG installed."
  else
    color_message "${GREEN}" "k3d is up to date ($K3D_TAG)."
  fi
}

# Function to uninstall k3d
uninstall_k3d() {
  if [[ -f "/usr/local/bin/k3d" ]]; then
    sudo rm -f "/usr/local/bin/k3d"
    color_message "${GREEN}" "k3d uninstalled."
  else
    color_message "${YELLOW}" "k3d is not installed."
  fi
}

# Function to test if the installed k3d client is working
test_k3d_installation() {
  if ! command -v k3d &> /dev/null; then
    color_message "${YELLOW}" "k3d not found. Is it on your PATH?"
    exit 1
  fi
  color_message "${GREEN}" "Run 'k3d --help' to see what you can do with it."
}

# Discover the operating system for this system.
K3D_OS="$(uname | tr '[:upper:]' '[:lower:]')"

# Discover the architecture for this system.
K3D_ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"

# Set the desired k3d version (e.g., "v4.0.0" or "latest" for the latest release)
K3D_TAG=$(wget "$LATEST_RELEASE_URL" --server-response -O /dev/null 2>&1 | awk '/^\s*Location: /{DEST=$2} END{ print DEST}' | grep -oE "[^/]+$" | cut -c2-)

# Main script execution
if [[ "$1" == "uninstall" ]]; then
  color_message "${RED}" "Uninstalling k3d..."
  uninstall_k3d
else
  color_message "${GREEN}" "Preparing to install or update k3d..."
  install_or_update_k3d
  test_k3d_installation
  
  # Enable bash completion for k3d
  if command -v k3d &> /dev/null; then
    color_message "${GREEN}" "Enabling bash completion for k3d..."
    k3d completion bash > k3d 
    sudo mv k3d /etc/bash_completion.d/
    source /etc/bash_completion.d/k3d
    color_message "${GREEN}" "Bash completion for k3d has been enabled."
  else
    color_message "${YELLOW}" "Bash completion not enabled because k3d is not found on your PATH."
  fi
fi