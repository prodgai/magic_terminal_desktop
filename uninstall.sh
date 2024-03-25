#!/bin/bash

# Define the installation directories
INSTALL_BASE_DIR="/usr/local/bin"
MAGIC_TERMINAL_DIR="$INSTALL_BASE_DIR/magic_terminal"
LOGS_DIR="~/Library/Logs/magic_terminal_logs"

# Remove the Magic Terminal directory and its contents
echo "Removing Magic Terminal directory: $MAGIC_TERMINAL_DIR"
rm -rf "$MAGIC_TERMINAL_DIR"

# Remove the symbolic link
echo "Removing symbolic link: $INSTALL_BASE_DIR/magict"
rm -f "$INSTALL_BASE_DIR/magict"

# Remove the line sourcing magic_terminal.sh from ~/.zshrc
echo "Removing magic_terminal.sh source from ~/.zshrc"
sed -i '' '/source .*\/magic_terminal.sh/d' ~/.zshrc

# Remove the cron job
echo "Removing cron job"
crontab -l | grep -v "$MAGIC_TERMINAL_DIR/logsync.py" | crontab -

# Optionally, remove the logs directory
read -p "Do you want to remove the logs directory $LOGS_DIR? (y/n): " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "Removing logs directory: $LOGS_DIR"
    rm -rf "$LOGS_DIR"
fi

echo "Magic Terminal uninstalled successfully."