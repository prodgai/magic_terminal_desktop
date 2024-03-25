#!/bin/bash

# Define the installation directories
INSTALL_BASE_DIR="/usr/local/bin"
MAGIC_TERMINAL_DIR="$INSTALL_BASE_DIR/magic_terminal"
LOGS_DIR="~/Library/Logs/magic_terminal_logs"

# Check for macOS
if [[ $(uname) != "Darwin" ]]; then
    echo "This script is intended to be used on macOS."
    exit 1
fi

# Check for Python 3
if ! command -v python3 &>/dev/null; then
    echo "Python 3 is not installed. Please install it and try again."
    exit 1
fi

# Check for requests module
python3 -c "import requests" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Python 'requests' module is not installed. Installing..."
    pip3 install requests
    if [ $? -ne 0 ]; then
        echo "Failed to install 'requests' module. Please install it manually with 'pip install requests'."
        exit 1
    fi
fi

# Create logdir if it doesn't exist
if [ ! -d ~/Library/Logs/magic_terminal_logs ]; then
    echo "Creating logs directory: $LOGS_DIR"
    mkdir -p "$LOGS_DIR"
fi

# Create magic_terminal directory if it doesn't exist
if [ ! -d "$MAGIC_TERMINAL_DIR" ]; then
    echo "Creating magic_terminal directory: $MAGIC_TERMINAL_DIR"
    mkdir -p "$MAGIC_TERMINAL_DIR"
fi

# Move magic_terminal.sh to $MAGIC_TERMINAL_DIR
echo "Copying magic_terminal.sh to $MAGIC_TERMINAL_DIR"
if cp magic_terminal.sh "$MAGIC_TERMINAL_DIR/magic_terminal.sh"; then
    echo "magic_terminal.sh copied successfully."
else
    echo "Failed to copy magic_terminal.sh. Please check permissions."
    exit 1
fi

# Set execute permissions for necessary files
echo "Setting execute permissions for scripts"
chmod +x "$MAGIC_TERMINAL_DIR"/{magic_terminal.sh,logsync.py,magict.py}

# Append line to source magic_terminal.sh in zshrc only if it doesn't exist
if ! grep -Fxq "source $MAGIC_TERMINAL_DIR/magic_terminal.sh" ~/.zshrc; then
    echo "Adding magic_terminal.sh to ~/.zshrc"
    echo "" >> ~/.zshrc
    echo "source $MAGIC_TERMINAL_DIR/magic_terminal.sh" >> ~/.zshrc
fi

# Move Python script to $MAGIC_TERMINAL_DIR
echo "Copying logsync.py to $MAGIC_TERMINAL_DIR"
if cp logsync.py "$MAGIC_TERMINAL_DIR/logsync.py"; then
    echo "logsync.py copied successfully."
else
    echo "Failed to copy logsync.py. Please check permissions."
    exit 1
fi

# Set up CLI
echo "Setting up CLI"
if cp cli/magict.py "$MAGIC_TERMINAL_DIR/magict.py"; then
    echo "magict.py copied successfully."
else
    echo "Failed to copy magict.py. Please check permissions."
    exit 1
fi

# Create symbolic links in /usr/local/bin
echo "Creating symbolic links"
ln -shf "$MAGIC_TERMINAL_DIR/magict.py" "$INSTALL_BASE_DIR/magict"

# Create cron job if it doesn't exist
if ! crontab -l 2>/dev/null | grep -q "$MAGIC_TERMINAL_DIR/logsync.py"; then
    echo "Creating cron job"
    (crontab -l 2>/dev/null; echo "@reboot /usr/local/bin/python3 $MAGIC_TERMINAL_DIR/logsync.py") | crontab -
else
    echo "Cron job already exists"
fi

# Cleanup (optional)
# Add any necessary cleanup steps here

echo "Magic Terminal installed successfully. Use 'magict help' for CLI options."