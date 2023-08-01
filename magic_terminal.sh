#!/bin/bash

if [ -z "$MAGIC_TERMINAL_LOGFILE" ]; then
  # Using terminal escape sequences for colors
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  NC='\033[0m' # No Color

  log_directory="$HOME/Library/Logs/magic_terminal"
  # Check if the directory exists
  if [ ! -d "$log_directory" ]; then
    # If the directory doesn't exist, create it
    mkdir -p "$log_directory"
    echo "Log directory $log_directory created."
  else
    echo "Log directory $log_directory already exists."
  fi

  # Generate a unique session UUID
  SESSION_ID=$(uuidgen)

  # Define log file name
  MAGIC_TERMINAL_LOGFILE="$log_directory/$SESSION_ID.log"

  echo -e "${GREEN}Starting terminal logging session. Your unique session ID is: ${RED}$SESSION_ID${NC}"
  # Start script command with appending mode and filename as session ID
  MAGIC_TERMINAL_LOGFILE=$MAGIC_TERMINAL_LOGFILE script -a "$MAGIC_TERMINAL_LOGFILE"

  # Calculate session end time once the script command exits
  SESSION_END_TIME=$(date)

  # Append the session end time to the log file
  echo "Session ended at: $SESSION_END_TIME" >> "$MAGIC_TERMINAL_LOGFILE"

  echo -e "${GREEN}Terminal logging session with ID ${RED}$SESSION_ID${NC} has ended. Your log is stored in ${RED}$MAGIC_TERMINAL_LOGFILE${NC}"

  # Exit the terminal
  exit
else
  # If MAGIC_TERMINAL_LOGFILE is set, then we are inside the script command session
  # Append the current date/time to the log file
  echo -e "${GREEN}Started logging session to: ${RED}$MAGIC_TERMINAL_LOGFILE${NC}"
fi


