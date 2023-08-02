#!/usr/bin/env python3
import os
import requests
import time
import glob
from datetime import datetime
import pathlib

# Set up your server information here.
API_SERVER = 'http://localhost:8000/terminal_sessions/terminal_session/'

# Set up your log directory here.
LOG_DIR = '~/Library/Logs/magic_terminal/'

# Set up your authentication information here.
USERNAME = 'admin'
PASSWORD = 'adminpass'

def sync_logs():
    # Get a list of all the log files
    log_files = glob.glob(os.path.expanduser(os.path.join(LOG_DIR, '*.log')))
    print("Log files: ", log_files)
    for log_file in log_files:
        with open(log_file, 'r') as file:
            logs = file.read()

        # Check if the session has ended
        if "Terminal logging session with ID" in logs:
            session_end = datetime.fromtimestamp(pathlib.Path(log_file).stat().st_mtime)
            session_end = session_end.isoformat()
        else:
            session_end = None

        # Get the creation time of the log file
        session_start = datetime.fromtimestamp(pathlib.Path(log_file).stat().st_ctime)

        # Construct the data to send to the server
        data = {
            'session_start': session_start.isoformat(),
            'session_end': session_end,
            'logs': logs,
            'local_filename': os.path.basename(log_file)
        }
        # Send the data to the server
        response = requests.post(
            API_SERVER, 
            auth=(USERNAME, PASSWORD),
            data=data
        )

        response.raise_for_status()

def main():
    while True:
        try:
            sync_logs()
            time.sleep(15)  # Wait for 1 minute
        except Exception as e:
            print("Error: ", e)
            time.sleep(15)

if __name__ == '__main__':
    main()
