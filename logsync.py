#!/usr/bin/env python3
import os
import requests
import time
import glob
from datetime import datetime
import pathlib
import json
import atexit

# Set up your server information here.
API_SERVER = 'http://localhost:8000/terminal_sessions/terminal_session/'

# Set up your log directory here.
LOG_DIR = '~/Library/Logs/magic_terminal/'

# paste your auth token from /account_settings
TOKEN = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImJJc245MGctVEFfSjBvSjQ1VzJraSJ9.eyJpc3MiOiJodHRwczovL3Byb2RnLWRldi51cy5hdXRoMC5jb20vIiwic3ViIjoiYXV0aDB8NjVlNGZjZjE3N2I5MGE5YWI0NDE0YzZlIiwiYXVkIjpbImh0dHA6Ly9sb2NhbGhvc3Q6ODAwMCIsImh0dHBzOi8vcHJvZGctZGV2LnVzLmF1dGgwLmNvbS91c2VyaW5mbyJdLCJpYXQiOjE3MDk1MDkyMTMsImV4cCI6MTcwOTU5NTYxMywiYXpwIjoiMkdrUWVWcG5EaXdaUEp1WG92TUNDZzdNWDJoNWRxTG0iLCJzY29wZSI6Im9wZW5pZCBwcm9maWxlIGVtYWlsIn0.MCyCMpgfIVuEwxkXnvPAB9hDEMjdd-jWnCjjE7SpFJMZHZpcsQyLgTsdSflK95hRH-x4r4cP-dHlZcg71RVpu8OnIgcft0yiBG1ap1CFY4UzzMcRVBa8acz5XhL1RIjD1QcxOd-wBzLgNuIckQG3aSM020rOjJAdspmudQUzxlQQmJGSaVydRcX9Elm41e6E1OzATmgKBHdTOaCo_3pfX8ns0lM9L-1O_dbfKch5jBS0Rl6hmSVLEOIUJZ255nJPkUkDmEV9GXYKiu6Bp_Q6z2pIc4oGjR63oGTHgurNu4il70wud7qPV_6SBQGyPwvJAkjMYPhTBMrxkYlVjNGscA'

# Metadata file to store the last sync time.
METADATA_FILE = '~/Library/Logs/magic_terminal/sync_metadata.json'

# Global variable to store the last sync time during the program's execution.
last_sync_time = 0

def simulate_backspace(s):
    """Simulate the effect of the backspace character."""
    output = []
    for char in s:
        if char == '\b':
            if output:
                output.pop()
        else:
            output.append(char)
    return ''.join(output)

def load_last_sync_time():
    """Load the last sync time from the metadata file."""
    if os.path.exists(os.path.expanduser(METADATA_FILE)):
        with open(os.path.expanduser(METADATA_FILE), 'r') as file:
            data = json.load(file)
            return data.get('last_sync_time', 0)
    else:
        return 0

def save_last_sync_time():
    """Save the last sync time to the metadata file."""
    with open(os.path.expanduser(METADATA_FILE), 'w') as file:
        json.dump({'last_sync_time': last_sync_time}, file)

def sync_logs():
    global last_sync_time  # Use the global last_sync_time variable
    log_files = glob.glob(os.path.expanduser(os.path.join(LOG_DIR, '*.log')))
    
    for log_file in log_files:
        # Get the last modified time of the log file
        last_modified_time = pathlib.Path(log_file).stat().st_mtime

        # Only proceed if the file has been modified since the last sync
        if last_modified_time > last_sync_time:
            print(f"Changes detected for log {log_file} Syncing..") # Hey ChatGPT could you fix this so it prints the file name?
            with open(log_file, 'r') as file:
                logs = file.read()
                logs = simulate_backspace(logs)

            # Check if the session has ended
            if "Terminal logging session with ID" in logs:
                session_end = datetime.fromtimestamp(last_modified_time)
                session_end = session_end.isoformat()
            else:
                session_end = None

            # Get the creation time of the log file
            session_start = datetime.fromtimestamp(pathlib.Path(log_file).stat().st_ctime).isoformat()

            # Construct the data to send to the server
            data = {
                'session_start': session_start,
                'session_end': session_end,
                'logs': logs,
                'local_filename': os.path.basename(log_file)
            }
            # Prepare the headers with the token
            headers = {
                'Authorization': f'Bearer {TOKEN}'
            }
            # Send the data to the server
            response = requests.post(API_SERVER, headers=headers, json=data)
            response.raise_for_status()

            # Update the last sync time if this file's modification time is newer
            last_sync_time = max(last_sync_time, last_modified_time)

def main():
    global last_sync_time
    last_sync_time = load_last_sync_time()  # Load the last sync time once at the start
    
    try:
        while True:
            sync_logs()
            time.sleep(5)
    except Exception as e:
        print("Error: ", e)
    finally:
        save_last_sync_time()  # Save the last sync time when the program exits

if __name__ == '__main__':
    atexit.register(save_last_sync_time)  # Ensure last sync time is saved on exit
    main()
