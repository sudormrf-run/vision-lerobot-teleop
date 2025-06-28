# WebSocket Server Setup for Vision Pro Hand Tracking

## Quick Start

1. **Install dependencies:**
   ```bash
   pip3 install websockets
   ```

2. **Start the server:**
   ```bash
   ./start_server.sh
   ```
   
   Or manually:
   ```bash
   python3 websocket_server.py
   ```

3. **Note your computer's IP address** shown when the server starts.

4. **On Vision Pro:**
   - Open the LeRobot Teleoperator app
   - Click "WebSocket Control"
   - Edit the server address to: `ws://YOUR_COMPUTER_IP:8765`
   - Click "Connect"

## Network Requirements

- Both devices must be on the **same network**
- Port 8765 must be accessible (check firewall settings)
- For macOS, you may need to allow incoming connections when prompted

## Troubleshooting

### Can't connect from Vision Pro
1. Check both devices are on the same WiFi network
2. Verify the IP address is correct
3. Try pinging from one device to another
4. Check firewall settings

### Finding your IP address manually
- **macOS**: `ifconfig | grep "inet " | grep -v 127.0.0.1`
- **Linux**: `hostname -I` or `ip addr show`
- **Windows**: `ipconfig` (look for IPv4 Address)

### Firewall issues on macOS
If you see a popup asking to allow connections, click "Allow". 
You can also add Python to the firewall exceptions in System Preferences > Security & Privacy > Firewall.

## Testing the Connection

Once connected, you should see:
- Connection status change to "Connected" in the Vision Pro app
- Log messages in the terminal showing received hand tracking data
- Message count increasing in the WebSocket Control panel

## Logging and Replay

### Recording Hand Tracking Data

To record Vision Pro hand tracking data for later replay:

```bash
python3 websocket_server.py --log --verbose
```

This will:
- Save all received messages to `logs/hand_tracking_YYYYMMDD_HHMMSS.json`
- Display all 26 joint coordinates (use without `--verbose` for compact output)

### Replaying Recorded Data

To replay recorded hand tracking data:

```bash
# Replay at normal speed
python3 websocket_client_test.py --replay logs/hand_tracking_20240628_143022.json

# Replay at 2x speed
python3 websocket_client_test.py --replay logs/hand_tracking_20240628_143022.json --speed 2.0

# Replay to a different server
python3 websocket_client_test.py --server ws://192.168.1.100:8765 --replay logs/hand_tracking_20240628_143022.json
```

This allows you to:
- Test robot control code without needing Vision Pro
- Debug specific hand movements
- Create reproducible test scenarios

## Data Format

The server receives JSON messages with hand joint positions:
```json
{
  "timestamp": 1234567890.123,
  "leftHand": {
    "joints": [[x, y, z], ...],  // 26 joints
    "trackedMask": 134217727     // Bit mask for tracked joints
  },
  "rightHand": {
    "joints": [[x, y, z], ...],
    "trackedMask": 134217727
  }
}
```