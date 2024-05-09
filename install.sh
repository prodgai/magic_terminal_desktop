#!/bin/bash

# Define the installation directories
INSTALL_BASE_DIR="/usr/local/bin"
MAGIC_TERMINAL_DIR="$INSTALL_BASE_DIR/magic_terminal"
LOGS_DIR="~/Library/Logs/magic_terminal_logs"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to run commands with sudo if necessary
function run_with_sudo() {
    local command="$1"
    local dir="$2"

    if [ -z "$SUDO_ENABLED" ]; then
        if ! [ -w "$dir" ]; then
            echo "Elevated permissions are required to write to $dir."
            read -p "Would you like to run the remaining commands with sudo? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                SUDO_ENABLED=true
            else
                echo "Operation cancelled."
                exit 1
            fi
        fi
    fi

    if [ "$SUDO_ENABLED" = true ]; then
        sudo sh -c "$command"
    else
        eval "$command"
    fi
}

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
if [ ! -d "$LOGS_DIR" ]; then
    echo "Creating logs directory: $LOGS_DIR"
    run_with_sudo "mkdir -p \"$LOGS_DIR\""
fi

# Create magic_terminal directory if it doesn't exist
if [ ! -d "$MAGIC_TERMINAL_DIR" ]; then
    echo "Creating magic_terminal directory: $MAGIC_TERMINAL_DIR"
    run_with_sudo "mkdir -p \"$MAGIC_TERMINAL_DIR\""
fi

# Move magic_terminal.sh to $MAGIC_TERMINAL_DIR
echo "Copying magic_terminal.sh to $MAGIC_TERMINAL_DIR"
run_with_sudo "cp \"$SCRIPT_DIR/magic_terminal.sh\" \"$MAGIC_TERMINAL_DIR/magic_terminal.sh\""

# Move Python script to $MAGIC_TERMINAL_DIR
echo "Copying logsync.py to $MAGIC_TERMINAL_DIR"
run_with_sudo "cp \"$SCRIPT_DIR/logsync.py\" \"$MAGIC_TERMINAL_DIR/logsync.py\""

# Set up CLI
echo "Setting up CLI"
run_with_sudo "cp \"$SCRIPT_DIR/cli/magict.py\" \"$MAGIC_TERMINAL_DIR/magict.py\""

# Set execute permissions for necessary files
echo "Setting execute permissions for scripts"
run_with_sudo "chmod +x \"$MAGIC_TERMINAL_DIR\"/{magic_terminal.sh,logsync.py,magict.py}"

# Append line to source magic_terminal.sh in zshrc only if it doesn't exist
if ! grep -Fxq "source $MAGIC_TERMINAL_DIR/magic_terminal.sh" ~/.zshrc; then
    echo "Adding magic_terminal.sh to ~/.zshrc"
    echo "" >> ~/.zshrc
    echo "source $MAGIC_TERMINAL_DIR/magic_terminal.sh" >> ~/.zshrc
fi

# Create symbolic links in /usr/local/bin
echo "Creating symbolic links"
run_with_sudo "ln -shf \"$MAGIC_TERMINAL_DIR/magict.py\" \"$INSTALL_BASE_DIR/magict\""

# Create cron job if it doesn't exist
if ! crontab -l 2>/dev/null | grep -q "$MAGIC_TERMINAL_DIR/logsync.py"; then
    echo "Creating cron job"
    (crontab -l 2>/dev/null; echo "@reboot /usr/local/bin/python3 $MAGIC_TERMINAL_DIR/logsync.py") | run_with_sudo crontab -
else
    echo "Cron job already exists"
fi

echo "Launching initial background run of logsync.py"
nohup /usr/local/bin/python3 $MAGIC_TERMINAL_DIR/logsync.py &
echo "Logsync.py is now running in the background."

# Change ownership of installed files and directories to the current user
echo "Changing ownership of installed files and directories"
run_with_sudo "chown -R $(whoami) \"$MAGIC_TERMINAL_DIR\" \"$INSTALL_BASE_DIR/magict\""

# Cleanup (optional)
# Add any necessary cleanup steps here

echo "Magic Terminal installed successfully. Use 'magict help' for CLI options."