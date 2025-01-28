#!/bin/bash
# Script to kill all processes named 'java'

echo "Listing all Java processes before killing..."
pgrep -a java  # Lists the process IDs and full command line

echo "Killing all Java processes..."
pkill -f java

# Wait briefly to allow process terminations to complete
sleep 2

echo "Listing all Java processes after attempting to kill..."
pgrep -a java  # Checks again and lists any remaining processes

if pgrep -f java > /dev/null; then
    echo "Some Java processes are still running."
else
    echo "All Java processes have been successfully killed."
fi
