#!/bin/bash

# Set the directory where nothing will be installed
INSTALL_DIR="$(pwd)/_nothing"
EXTENSIONS_DIR="$INSTALL_DIR/extensions"
INACTIVE_EXTENSIONS_DIR="$EXTENSIONS_DIR/inactive"

# Create the installation and extensions directories
mkdir -p "$EXTENSIONS_DIR"
mkdir -p "$INACTIVE_EXTENSIONS_DIR"

# Navigate to the installation directory
cd "$INSTALL_DIR" || exit 1

# Download the nothing.rb script
echo "Downloading nothing.rb..."
curl -o nothing.rb https://raw.githubusercontent.com/adamjgrant/nothing/refs/heads/main/_nothing/nothing.rb

# Verify the download
if [[ ! -f "nothing.rb" ]]; then
  echo "Failed to download nothing.rb. Please check your connection and try again."
  exit 1
fi

# Download extensions
EXTENSIONS=("push" "repeat" "nlp" "overdue" "amnesia")
echo "Downloading extensions..."
for EXT in "${EXTENSIONS[@]}"; do
  if [[ "$EXT" == "amnesia" ]]; then
    EXT_URL="https://raw.githubusercontent.com/adamjgrant/nothing/refs/heads/main/_nothing/extensions/inactive/$EXT.rb"
    DEST_DIR="$INACTIVE_EXTENSIONS_DIR"
  else
    EXT_URL="https://raw.githubusercontent.com/adamjgrant/nothing/refs/heads/main/_nothing/extensions/inactive/$EXT.rb"
    DEST_DIR="$EXTENSIONS_DIR"
  fi
  
  curl -o "$DEST_DIR/$EXT.rb" "$EXT_URL"
  if [[ ! -f "$DEST_DIR/$EXT.rb" ]]; then
    echo "Failed to download $EXT extension."
  else
    echo "Downloaded $EXT extension to $DEST_DIR."
  fi
done

# Add cron job
echo "Adding cron job..."
CRON_JOB="* * * * * LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 cd $INSTALL_DIR && ruby nothing.rb"
(crontab -l 2>/dev/null | grep -F "$CRON_JOB") && echo "Cron job already exists." || (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

# Final message
echo "Setup complete. Nothing is installed and will now run automatically."
echo "                                                           
                                                           
                                                           
  '|.   '|'           .   '||       ||                     
   |'|   |    ...   .||.   || ..   ...  .. ...     ... .   
   | '|. |  .|  '|.  ||    ||' ||   ||   ||  ||   || ||    
   |   |||  ||   ||  ||    ||  ||   ||   ||  ||    |''     
  .|.   '|   '|..|'  '|.' .||. ||. .||. .||. ||.  '||||.   
                                                 .|....'   
                                                           
                                                           
                                                           "
# Advising the user about crontab delay
echo "Note: The cron job runs every minute. Please allow up to a minute for the first execution.
During this time, you may not see any changes. The installation script will disappear and setup
will complete with the first execution of NOTHING.

Learn how to use Nothing: https://adamgrant.info/nothing"