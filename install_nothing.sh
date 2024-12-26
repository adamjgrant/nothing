#!/bin/bash

# Set the directory where nothing will be installed
INSTALL_DIR="$(pwd)/_nothing"

# Create the installation directory
mkdir -p "$INSTALL_DIR"

# Navigate to the directory
cd "$INSTALL_DIR" || exit 1

# Download the nothing.rb script
echo "Downloading nothing.rb..."
curl -o nothing.rb https://raw.githubusercontent.com/adamjgrant/nothing/refs/heads/main/_nothing/nothing.rb

# Verify the download
if [[ ! -f "nothing.rb" ]]; then
  echo "Failed to download nothing.rb. Please check your connection and try again."
  exit 1
fi

# Add cron job
echo "Adding cron job..."
CRON_JOB="* * * * * LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 cd $INSTALL_DIR && ruby nothing.rb"
(crontab -l 2>/dev/null | grep -F "$CRON_JOB") && echo "Cron job already exists." || (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

# Final message
echo "Setup complete. Nothing is installed and will now run automatically."