#!/bin/bash

# Function to install Ruby based on the detected platform
install_ruby() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Detect Linux distribution
    if command -v apt-get &> /dev/null; then
      echo "Detected Debian-based system. Installing Ruby..."
      sudo apt-get update
      sudo apt-get install -y ruby-full
    elif command -v yum &> /dev/null; then
      echo "Detected Red Hat-based system. Installing Ruby..."
      sudo yum install -y ruby
    elif command -v pacman &> /dev/null; then
      echo "Detected Arch Linux system. Installing Ruby..."
      sudo pacman -Syu --noconfirm ruby
    else
      echo "Unsupported Linux distribution. Please install Ruby manually."
      exit 1
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    echo "Detected macOS. Installing Ruby..."
    if ! command -v brew &> /dev/null; then
      echo "Homebrew not found. Installing Homebrew first..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install ruby
  elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then
    # Windows with Git Bash or Cygwin
    echo "Detected Windows. Installing Ruby..."
    if ! command -v choco &> /dev/null; then
      echo "Chocolatey not found. Please install Chocolatey first: https://chocolatey.org/install"
      exit 1
    fi
    choco install ruby -y
  else
    echo "Unsupported operating system. Please install Ruby manually."
    exit 1
  fi
}

# Check if Ruby is installed
if ! command -v ruby &> /dev/null; then
  echo "Ruby is not installed."
  read -p "Do you want to install Ruby? (yes/no): " choice
  if [[ "$choice" == "yes" ]]; then
    install_ruby
    if command -v ruby &> /dev/null; then
      echo "Ruby has been installed successfully."
    else
      echo "Failed to install Ruby. Please install it manually."
      exit 1
    fi
  else
    echo "Ruby installation skipped. Exiting..."
    exit 1
  fi
else
  echo "Ruby is already installed."
fi

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
CRON_JOB="* * * * * LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 cd \"$INSTALL_DIR\" && ruby nothing.rb"
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
echo "Note: The cron job runs every minute, so allow up to a minute for the first execution. During this time, you may not see any changes. The installation script will disappear and setup will complete with the first execution of NOTHING.

If that does not happen, try running this cron manually to detect any errors:

$CRON_JOB

Learn how to use Nothing: https://adamgrant.info/nothing"