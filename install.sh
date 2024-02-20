#!/bin/bash

# Define the installation directory
MAIN_DIR="/usr/local/bin"
INSTALL_DIR="$MAIN_DIR/magic_terminal"
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
    pip3 install requests  # Automatically install requests using pip
    if [ $? -ne 0 ]; then
        echo "Failed to install 'requests' module. Please install it manually with 'pip install requests'."
        exit 1
    fi
fi

# Create logdir if it doesn't exist
if [ ! -d ~/Library/Logs/magic_terminal_logs ]; then
    mkdir $LOGS_DIR
fi

# Create magic_terminal directory if it doesn't exist
if [ ! -d $INSTALL_DIR ]; then
    mkdir -p $INSTALL_DIR
fi

# Move magic_terminal.sh to $INSTALL_DIR
cp magic_terminal.sh $INSTALL_DIR/magic_terminal.sh
chmod +x $INSTALL_DIR/magic_terminal.sh

# Append line to source magic_terminal.sh in zshrc only if it doesn't exist
if ! grep -Fxq "source $INSTALL_DIR/magic_terminal.sh" ~/.zshrc; then
    echo "" >> ~/.zshrc
    echo "source $INSTALL_DIR/magic_terminal.sh" >> ~/.zshrc
fi

# Move Python script to $INSTALL_DIR
cp logsync.py $INSTALL_DIR/logsync.py
chmod +x $INSTALL_DIR/logsync.py

# set up CLI
cp cli/magict.py $INSTALL_DIR/magict.py
# Create symbolic links in /usr/local/bin
ln -sf $INSTALL_DIR/magict.py $MAIN_DIR/magict
chmod +x $INSTALL_DIR/magict.py


# Create cron job
# (crontab -l; echo "@reboot /usr/local/bin/python3 /usr/local/bin/logsync.py") | crontab -


echo "Magic Terminal installed successfully. Use "magict help" for CLI options."
