#!/usr/bin/env python3
import os
import requests
import time
import glob
from datetime import datetime
import pathlib
import json
import atexit
import logging
import pyte

# Setup basic logging
LOG_FILENAME = '/tmp/magic_terminal_logs'
logging.basicConfig(filename=LOG_FILENAME, level=logging.INFO, format='%(asctime)s %(levelname)s:%(message)s')

# Set up your server information here.
API_SERVER = 'http://localhost/terminal_sessions/terminal_session/'

# Set up your log directory here.
LOG_DIR = '~/Library/Logs/magic_terminal/'

# paste your auth token from /account_settings
TOKEN = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImJJc245MGctVEFfSjBvSjQ1VzJraSJ9.eyJpc3MiOiJodHRwczovL3Byb2RnLWRldi51cy5hdXRoMC5jb20vIiwic3ViIjoiYXV0aDB8NjVkNDI3NDQ3YzkxODM4ZGU3NTQwMWVjIiwiYXVkIjpbImh0dHA6Ly9sb2NhbGhvc3QiLCJodHRwczovL3Byb2RnLWRldi51cy5hdXRoMC5jb20vdXNlcmluZm8iXSwiaWF0IjoxNzE1MjkwNDY3LCJleHAiOjE3MTUzNzY4NjcsInNjb3BlIjoib3BlbmlkIHByb2ZpbGUgZW1haWwiLCJhenAiOiIyR2tRZVZwbkRpd1pQSnVYb3ZNQ0NnN01YMmg1ZHFMbSJ9.CiqcJhp7NfCurAAe2n0wNUH2QThzLnN2ZiOQQLKfkNpItX2GEMrCDi712DbanxTyxZVCqnKinUo4CHIgnZO-JTtHu6cgoW5394-4kR1114ViD7KyrdsGY8yzCxftbDcE7Ub4aZng10S2obV-9gm21lHg44SYvhn8FqFUgl25SjbF9wRtlyPCsd9Nwxuhx8Qgu4NMD-1yqfEilvZAENV3uWQUiYjZC4GN_82qUAbldKDKcgMxafgStvBODhxWDT5rMmcaspE7rt9VFw2dDEubU4WlXKmOYxMQuAyzxow9eFUj7Fc6NvJAS4A4gv1l6kK7q6cfFukYz17nAreLQrjOAQ'
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
    logging.info("Last sync time saved.")

def format_logs(log_content):
    # Create a screen that emulates the size of a typical terminal
    screen = pyte.Screen(800, 2000)
    stream = pyte.ByteStream(screen)

    # Feed the log content to the stream
    stream.feed(log_content)
    html_output = ""
    for line in screen.display:

        html_output += line.replace('\r\n', '\n').replace('\r', '\n').replace('\n', '') + '\n'

    return html_output

def sync_logs():
    global last_sync_time  # Use the global last_sync_time variable
    log_files = glob.glob(os.path.expanduser(os.path.join(LOG_DIR, '*.log')))
    
    for log_file in log_files:
        # Get the last modified time of the log file
        last_modified_time = pathlib.Path(log_file).stat().st_mtime

        # Only proceed if the file has been modified since the last sync
        if last_modified_time > last_sync_time:
            logging.info(f"Changes detected for log {log_file}. Syncing..")
            with open(log_file, 'rb') as file:
                logs = format_logs(file.read())

            # Check if the session has ended
            if "Terminal logging session with ID" in logs:
                session_end = datetime.fromtimestamp(last_modified_time)
                session_end = session_end.isoformat()
            else:
                session_end = None

            # Get the creation time of the log file
            session_start = datetime.fromtimestamp(pathlib.Path(log_file).stat().st_ctime).isoformat()
            print(logs)
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
            try:
                response = requests.post(API_SERVER, headers=headers, json=data)
                response.raise_for_status()
            except Exception as e:
                logging.error(f"Failed to sync logs for {log_file}: {e}")

            # Update the last sync time if this file's modification time is newer
            last_sync_time = max(last_sync_time, last_modified_time)

def main():
    global last_sync_time
    last_sync_time = load_last_sync_time()  # Load the last sync time once at the start
    logging.info("Started sync process.")
    
    try:
        while True:
            sync_logs()
            time.sleep(30)
    except Exception as e:
        logging.error(f"Error in sync loop: {e}")
    finally:
        save_last_sync_time()  # Save the last sync time when the program exits

if __name__ == '__main__':
    atexit.register(save_last_sync_time)  # Ensure last sync time is saved on exit
    main()
