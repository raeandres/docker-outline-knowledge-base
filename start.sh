#!/bin/bash

# Set default port if not provided
export PORT=${PORT:-10000}
export HOST=${HOST:-0.0.0.0}

echo "Starting Outline on $HOST:$PORT"

# Start the application
exec yarn start
