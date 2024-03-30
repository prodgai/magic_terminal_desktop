#!/bin/bash

# Define the installation directories
INSTALL_BASE_DIR="/usr/local/bin"
MAGIC_TERMINAL_DIR="$INSTALL_BASE_DIR/magic_terminal"
LOGS_DIR="~/Library/Logs/magic_terminal_logs"

# Function to run commands with sudo if necessary
function run_with_sudo() {
    local command="$1"

    if [ -z "$SUDO_ENABLED" ]; then
        read -p "This operation requires elevated permissions. Would you like to run the commands with sudo? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            SUDO_ENABLED=true
        else
            echo "Operation cancelled."
            exit 1
        fi
    fi

    if [ "$SUDO_ENABLED" = true ]; then
        sudo sh -c "$command"
    else
        eval "$command"
    fi
}

# Remove magic_terminal directory and its contents
if [ -d "$MAGIC_TERMINAL_DIR" ]; then
    echo "Removing $MAGIC_TERMINAL_DIR"
    run_with_sudo "rm -rf \"$MAGIC_TERMINAL_DIR\""
fi

# Remove symbolic link in /usr/local/bin
if [ -L "$INSTALL_BASE_DIR/magict" ]; then
    echo "Removing $INSTALL_BASE_DIR/magict"
    run_with_sudo "rm \"$INSTALL_BASE_DIR/magict\""
fi

# Remove log directory
if [ -d "$LOGS_DIR" ]; then
    echo "Removing $LOGS_DIR"
    run_with_sudo "rm -rf \"$LOGS_DIR\""
fi

# Remove cron job
if crontab -l 2>/dev/null | grep -q "$MAGIC_TERMINAL_DIR/logsync.py"; then
    echo "Removing cron job"
    (crontab -l 2>/dev/null | grep -v "$MAGIC_TERMINAL_DIR/logsync.py") | run_with_sudo crontab -
fi

# Remove line from ~/.zshrc
if grep -Fxq "source $MAGIC_TERMINAL_DIR/magic_terminal.sh" ~/.zshrc; then
    echo "Removing magic_terminal.sh from ~/.zshrc"
    sed -i '' "/source $MAGIC_TERMINAL_DIR\/magic_terminal.sh/d" ~/.zshrc
fi

echo "Magic Terminal uninstalled successfully."