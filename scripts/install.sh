#!/bin/bash

# Update package lists
echo "Updating package lists..."
sudo apt update

# Install Google Chrome (stable version) or Chromium (uncomment one option)
echo "Installing Google Chrome..."
sudo apt install -y google-chrome-stable

# Or install Chromium (if you prefer) instead of Google Chrome
# echo "Installing Chromium..."
# sudo apt install -y chromium-browser

# Find the installed browser path (Chrome or Chromium)
CHROME_PATH=$(which google-chrome-stable)
# For Chromium, uncomment the next line
# CHROME_PATH=$(which chromium-browser)

# Check if the browser was installed successfully
if [ -z "$CHROME_PATH" ]; then
    echo "Error: Chrome or Chromium installation failed."
    exit 1
fi

# Set the CHROME_PATH environment variable
echo "Setting CHROME_PATH environment variable to $CHROME_PATH..."
echo "export CHROME_PATH=$CHROME_PATH" >> ~/.bashrc  # For bash
# For zsh, uncomment the next line
# echo "export CHROME_PATH=$CHROME_PATH" >> ~/.zshrc

# Reload shell configuration to apply the change
echo "Reloading shell configuration..."
source ~/.bashrc  # For bash
# For zsh, uncomment the next line
# source ~/.zshrc

# Verify CHROME_PATH is set
echo "CHROME_PATH is set to: $CHROME_PATH"

echo "Chrome/Chromium is installed and CHROME_PATH is configured."

# End of script
