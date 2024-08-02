#!/bin/bash
# Script to kill all processes named 'java'

# Find all running java processes and kill them
echo "Killing all Java processes..."
pkill -f java

echo "All Java processes have been killed."
