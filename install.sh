#!/bin/bash

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
    echo "Python 'requests' module is not installed. Install it with 'pip install requests'."
    exit 1
fi

# Create logdir if it doesn't exist
if [ ! -d ~/Library/Logs/magic_terminal_logs ]; then
    mkdir ~/Library/Logs/magic_terminal_logs
fi

# Move magic_terminal.sh to /usr/local/bin
cp magic_terminal.sh /usr/local/bin/magic_terminal.sh
chmod +x /usr/local/bin/magic_terminal.sh

# Append line to source magic_terminal.sh in zshrc only if it doesn't exist
if ! grep -Fxq "source /usr/local/bin/magic_terminal.sh" ~/.zshrc; then
    echo "" >> ~/.zshrc
    echo "source /usr/local/bin/magic_terminal.sh" >> ~/.zshrc
fi

# Move Python script to /usr/local/bin
cp logsync.py /usr/local/bin/logsync.py
chmod +x /usr/local/bin/logsync.py

# Create cron job
# (crontab -l; echo "@reboot /usr/local/bin/python3 /usr/local/bin/logsync.py") | crontab -
