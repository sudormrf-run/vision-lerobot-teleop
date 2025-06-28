#!/bin/bash

echo "=== Vision Pro Hand Tracking WebSocket Server ==="
echo ""

# Get the machine's IP address
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1)
else
    # Linux
    IP=$(hostname -I | awk '{print $1}')
fi

if [ -z "$IP" ]; then
    echo "Could not determine IP address automatically."
    echo "Please find your IP address manually using:"
    echo "  macOS: ifconfig"
    echo "  Linux: ip addr or hostname -I"
    IP="YOUR_IP_HERE"
fi

PORT=8765

echo "Server will listen on: 0.0.0.0:$PORT"
echo ""
echo "On your Vision Pro, use this address in WebSocket Control:"
echo "  ws://$IP:$PORT"
echo ""
echo "Make sure both devices are on the same network!"
echo ""
echo "Starting server..."
echo "=========================================="
echo ""

# Check if websockets is installed
python3 -c "import websockets" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "ERROR: websockets module not found!"
    echo "Install it with: pip3 install websockets"
    exit 1
fi

# Run the server
python websocket_server.py
