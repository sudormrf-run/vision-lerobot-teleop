# Vision Pro Hand Tracking Integration

This document describes the Vision Pro hand tracking app implementation and the data format it sends to the server for robot teleoperation.

## Overview

The Vision Pro app captures hand tracking data using Apple's ARKit framework and sends it to a server via HTTP POST requests. The app tracks both left and right hands simultaneously and transmits their joint positions in real-time.

## Data Format

### HTTP Endpoint

The app sends hand tracking data to:
```
POST http://<server-ip>:<port>/control
```

### Message Structure

The app sends JSON messages with the following structure:

```json
{
  "timestamp": 1751465222.876336,
  "leftHand": {
    "joints": [
      [x1, y1, z1],  // Joint 0 position
      [x2, y2, z2],  // Joint 1 position
      ...            // Total 26 joints
    ],
    "trackedMask": 67108863  // Bit mask indicating which joints are tracked
  },
  "rightHand": {
    "joints": [
      [x1, y1, z1],
      [x2, y2, z2],
      ...
    ],
    "trackedMask": 67108863
  }
}
```

### Hand Joint Details

Each hand contains 26 joints following Apple's hand skeleton structure:
- Wrist (1 joint)
- Thumb (4 joints)
- Index finger (5 joints)
- Middle finger (5 joints)  
- Ring finger (5 joints)
- Little finger (5 joints)
- Forearm (1 joint)

The `trackedMask` is a bit field where each bit indicates whether the corresponding joint is being tracked (1) or not (0).

### Coordinate System

- Positions are in meters
- Coordinate system follows ARKit conventions:
  - X: Right
  - Y: Up
  - Z: Forward (towards user)

## Testing Scripts

### HTTP Server (`scripts/http_hand_tracking_server.py`)

A simple HTTP server that receives and logs hand tracking data:

```bash
# Start the server
python scripts/http_hand_tracking_server.py

# Options:
# --host: Server host (default: 0.0.0.0)
# --port: Server port (default: 1049)
# --log-dir: Directory to save logs (default: logs/)
```

The server will:
- Listen for POST requests on `/control`
- Log received data to timestamped JSON files
- Provide a health check endpoint at `/health`

### Replay Script (`scripts/http_hand_tracking_replay.py`)

Replays logged hand tracking data for testing:

```bash
# Replay a log file
python scripts/http_hand_tracking_replay.py logs/hand_tracking_20250702_230702.json

# Options:
# --server: Target server URL (default: http://localhost:1049)
# --speed: Playback speed multiplier (default: 1.0)
# --start-frame: Starting frame number (default: 0)
# --max-frames: Maximum frames to replay (default: all)
```

## Implementation Notes

### Update Frequency
The Vision Pro app sends updates at approximately 120-130Hz when hands are tracked, though the actual frequency can vary based on tracking conditions and system performance.

### Network Configuration
1. Ensure both Vision Pro and server are on the same network
2. Update the server IP in the Vision Pro app's HTTP Control panel
3. Default port is 1049 (configurable)

### Error Handling
- The app will retry failed requests after a short delay
- Connection state is displayed in the UI
- Health check endpoint can be used to verify server connectivity

## References

- [Apple Developer Documentation: Tracking and Visualizing Hand Movement](https://developer.apple.com/documentation/visionos/tracking-and-visualizing-hand-movement)
- Vision Pro Hand Tracking API Reference
- ARKit Hand Tracking Documentation

## Example Server Implementation

Here's a minimal Python server example that receives the hand tracking data:

```python
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/control', methods=['POST'])
def control():
    data = request.json
    timestamp = data.get('timestamp')
    left_hand = data.get('leftHand')
    right_hand = data.get('rightHand')
    
    # Process hand data here
    if left_hand:
        process_hand(left_hand, is_left=True)
    if right_hand:
        process_hand(right_hand, is_left=False)
    
    return jsonify({"status": "ok"})

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "healthy"})

def process_hand(hand_data, is_left):
    joints = hand_data['joints']
    tracked_mask = hand_data['trackedMask']
    
    # Convert joint positions to robot commands
    # Implementation depends on your robot's API
    pass

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=1049)
```