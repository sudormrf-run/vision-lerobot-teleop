# Vision Pro Teleoperation Architecture Design Document (ARD)

## 1. Executive Summary

This document describes the architecture for integrating Apple Vision Pro hand tracking with the LeRobot framework for teleoperation of the SO Arm 101 robot. The design leverages LeRobot's existing teleoperation infrastructure while introducing a new VisionProTeleoperator class that translates hand gestures into robot actions.

## 2. System Architecture

### 2.1 High-Level Architecture

```
┌─────────────────────┐     WebSocket      ┌──────────────────────┐
│   Vision Pro App    │ ◄─────────────────► │  Bridge Server       │
│  (Swift/visionOS)   │                     │  (Python/asyncio)    │
└─────────────────────┘                     └──────────────────────┘
                                                        │
                                                        │ Local API
                                                        ▼
                                            ┌──────────────────────┐
                                            │ VisionProTeleoperator │
                                            │   (LeRobot Plugin)   │
                                            └──────────────────────┘
                                                        │
                                                        │ Action Dict
                                                        ▼
                                            ┌──────────────────────┐
                                            │    SO Arm 101        │
                                            │  (Robot Hardware)    │
                                            └──────────────────────┘
```

### 2.2 Data Flow Architecture

```
Hand Tracking → Gesture Data → Action Commands → Motor Commands → Robot Movement
     ↓              ↓                ↓                 ↓              ↓
  30-60 Hz      WebSocket       LeRobot API      Serial/USB      Physical
```

## 3. Data Structures

### 3.1 Gesture Data Structure (Vision Pro → Bridge)

```python
@dataclass
class VisionProGestureData:
    """Hand tracking data from Vision Pro"""
    timestamp: float
    left_hand: Optional[HandData]
    right_hand: Optional[HandData]
    
@dataclass
class HandData:
    """Individual hand tracking data"""
    is_tracked: bool
    confidence: float
    
    # Joint positions (21 joints per hand)
    joints: Dict[str, JointData]  # wrist, thumb_tip, index_tip, etc.
    
    # Hand pose classification
    gesture: str  # "open", "closed", "pinch", "point", etc.
    
    # Transform data
    position: np.ndarray  # [x, y, z] in meters
    rotation: np.ndarray  # [qx, qy, qz, qw] quaternion

@dataclass 
class JointData:
    """Individual joint data"""
    position: np.ndarray  # [x, y, z] relative to wrist
    confidence: float
```

### 3.2 Action Data Structure (Following LeRobot Convention)

```python
# Action dictionary format for SO Arm 101
action = {
    # Joint positions (6 DOF + gripper)
    "shoulder_pan": float,      # -π to π radians
    "shoulder_lift": float,     # -π/2 to π/2 radians  
    "elbow": float,            # -π to π radians
    "wrist_1": float,          # -π to π radians
    "wrist_2": float,          # -π to π radians
    "wrist_3": float,          # -π to π radians
    "gripper": float,          # 0.0 (closed) to 1.0 (open)
    
    # Optional velocity/acceleration limits
    "max_velocity": float,      # rad/s
    "max_acceleration": float,  # rad/s²
}
```

### 3.3 Observation Data Structure

```python
observation = {
    "state": np.ndarray,  # [7] joint positions + gripper
    "images": {
        "front": np.ndarray,  # (480, 640, 3) RGB image
        "wrist": np.ndarray,  # (480, 640, 3) RGB image
    },
    "timestamp": float,
    "episode_index": int,
    "frame_index": int,
}
```

### 3.4 WebSocket Message Protocol

```python
# Request/Response format
@dataclass
class TeleopMessage:
    type: str  # "gesture", "action", "observation", "control"
    data: dict
    timestamp: float
    sequence_id: int

# Message types:
# 1. Gesture Update (Vision Pro → Bridge)
{
    "type": "gesture",
    "data": VisionProGestureData.to_dict(),
    "timestamp": 1234567890.123,
    "sequence_id": 1001
}

# 2. Action Command (Bridge → Robot)
{
    "type": "action", 
    "data": action_dict,
    "timestamp": 1234567890.456,
    "sequence_id": 1002
}

# 3. Observation Update (Robot → Bridge → Vision Pro)
{
    "type": "observation",
    "data": {
        "state": state.tolist(),
        "has_images": true,
        "image_urls": {...}  # Optional for bandwidth
    },
    "timestamp": 1234567890.789,
    "sequence_id": 1003
}
```

## 4. Component Design

### 4.1 VisionProTeleoperator Class

```python
class VisionProTeleoperator(Teleoperator):
    """LeRobot teleoperator for Vision Pro hand tracking"""
    
    def __init__(self, config: VisionProTeleoperatorConfig):
        super().__init__(config)
        self.bridge_client = BridgeClient(config.bridge_url)
        self.gesture_buffer = GestureBuffer(size=10)
        self.mapping_strategy = config.mapping_strategy
        
    def get_action(self) -> dict:
        """Convert latest gesture to robot action"""
        gesture = self.bridge_client.get_latest_gesture()
        self.gesture_buffer.add(gesture)
        
        # Apply mapping strategy
        if self.mapping_strategy == "direct":
            return self._direct_mapping(gesture)
        elif self.mapping_strategy == "gesture":
            return self._gesture_mapping(gesture)
        elif self.mapping_strategy == "hybrid":
            return self._hybrid_mapping(gesture)
            
    def _direct_mapping(self, gesture: VisionProGestureData) -> dict:
        """Map hand position/rotation directly to end-effector"""
        # Implementation details...
        
    def _gesture_mapping(self, gesture: VisionProGestureData) -> dict:
        """Map recognized gestures to discrete actions"""
        # Implementation details...
```

### 4.2 Bridge Server Architecture

```python
class VisionProBridge:
    """WebSocket bridge between Vision Pro and LeRobot"""
    
    def __init__(self):
        self.websocket_server = WebSocketServer()
        self.gesture_queue = asyncio.Queue(maxsize=100)
        self.observation_queue = asyncio.Queue(maxsize=100)
        
    async def handle_vision_pro_connection(self, websocket):
        """Handle incoming Vision Pro connections"""
        
    async def process_gestures(self):
        """Process gesture queue and generate actions"""
        
    async def broadcast_observations(self):
        """Send robot observations back to Vision Pro"""
```

## 5. Mapping Strategies

### 5.1 Direct Mapping
- Hand position → End-effector position (scaled)
- Hand rotation → End-effector rotation
- Pinch gesture → Gripper control
- Suitable for precise manipulation tasks

### 5.2 Gesture-Based Mapping
- Open hand → Stop/Pause
- Closed fist → Enable movement
- Swipe gestures → Directional movement
- Pinch → Pick/Place
- Suitable for discrete action tasks

### 5.3 Hybrid Mapping
- Gesture to enable/disable control modes
- Direct mapping when enabled
- Safety gestures always active
- Best for general teleoperation

## 6. Safety and Performance Considerations

### 6.1 Safety Features
- Workspace boundaries
- Velocity/acceleration limits
- Emergency stop gesture (both hands closed)
- Deadman switch (hand tracking confidence)
- Collision detection integration

### 6.2 Performance Optimization
- Gesture buffer for smoothing (10-frame window)
- Predictive filtering for latency compensation
- Efficient serialization (MessagePack/Protocol Buffers)
- Connection pooling and reconnection logic
- Frame skipping for high-frequency updates

## 7. Integration Points

### 7.1 LeRobot Integration
- Implements `Teleoperator` abstract base class
- Compatible with `record.py` for dataset creation
- Works with existing robot implementations
- Supports calibration save/load

### 7.2 Vision Pro App Requirements
- ARKit hand tracking APIs
- WebSocket client implementation
- Real-time gesture recognition
- Visual feedback rendering
- Network state management

## 8. Data Recording Format

Following LeRobot conventions:
- Episodes stored as Parquet files
- Actions include full joint state
- Observations include robot state + images
- Metadata tracks gesture confidence and mapping mode
- Compatible with existing LeRobot datasets

## 9. Future Extensibility

- Multi-robot control
- Haptic feedback integration
- AR visualization overlay
- Machine learning gesture recognition
- Cloud-based teleoperation
- VR headset support