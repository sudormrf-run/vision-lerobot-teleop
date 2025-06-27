# Vision Pro Robot Teleoperation Project Plan

## Project Overview
Develop a teleoperation system that uses Apple Vision Pro's hand gesture tracking to control a SO Arm 101 robot with precise motor-level control, enabling action data recording for robot learning applications.

## System Architecture

### Components
1. **Vision Pro Application (SwiftUI/visionOS)**
   - Hand gesture tracking and recognition
   - Real-time gesture processing
   - Network communication client
   - Visual feedback and UI

2. **Communication Bridge**
   - WebSocket server (recommended for low-latency)
   - Protocol buffer or JSON message formatting
   - Mac-to-Linux network bridge
   - Message queue for reliable delivery

3. **Robot Control System (Linux/Python)**
   - LeRobot framework integration
   - Motor command translation
   - Safety limits and validation
   - Action data recording

4. **Data Pipeline**
   - Gesture-to-motor mapping
   - Action sequence recording
   - Timestamped data storage
   - Replay functionality

## Technical Requirements

### Hardware
- Apple Vision Pro with hand tracking
- Mac computer (for Vision Pro development)
- SO Arm 101 robot
- Linux computer (robot control)
- Network connection between Mac and Linux

### Software
- visionOS SDK
- SwiftUI framework
- Python 3.8+
- LeRobot framework
- WebSocket libraries

## Implementation Phases

### Phase 1: Basic Infrastructure (Week 1-2)
- [ ] Set up development environment
- [ ] Create basic Vision Pro app with hand tracking
- [ ] Establish WebSocket communication
- [ ] Test basic message passing

### Phase 2: Gesture Recognition (Week 3-4)
- [ ] Implement hand gesture detection
- [ ] Define gesture-to-command mapping
- [ ] Create gesture calibration system
- [ ] Test gesture recognition accuracy

### Phase 3: Robot Integration (Week 5-6)
- [ ] Integrate with LeRobot framework
- [ ] Implement motor control interface
- [ ] Add safety mechanisms
- [ ] Test basic robot movements

### Phase 4: Data Recording (Week 7-8)
- [ ] Implement action recording system
- [ ] Create data storage format
- [ ] Add replay functionality
- [ ] Test data quality

### Phase 5: Refinement (Week 9-10)
- [ ] Optimize latency
- [ ] Improve gesture accuracy
- [ ] Add advanced features
- [ ] Documentation and testing

## Key Technical Decisions

### Communication Protocol
**WebSocket** chosen for:
- Low latency bidirectional communication
- Cross-platform compatibility
- Easy integration with both Swift and Python
- Real-time streaming capabilities

### Data Format
**Protocol Buffers** recommended for:
- Efficient serialization
- Strong typing
- Cross-language support
- Compact message size

### Control Strategy
**Direct Motor Mapping** approach:
- Map hand joint angles to robot joint angles
- Apply scaling and safety limits
- Enable fine-grained control
- Support demonstration recording

## Risk Mitigation

### Technical Risks
1. **Latency Issues**
   - Mitigation: Local network, optimized protocols
   
2. **Gesture Accuracy**
   - Mitigation: Calibration system, filtering algorithms
   
3. **Safety Concerns**
   - Mitigation: Speed limits, emergency stops, workspace boundaries

### Development Risks
1. **Platform Integration**
   - Mitigation: Early prototype testing
   
2. **Hardware Limitations**
   - Mitigation: Performance profiling, optimization

## Success Metrics
- Gesture recognition accuracy > 95%
- Control latency < 50ms
- Smooth robot movement
- Reliable data recording
- Successful action replay

## Next Steps
1. Set up development environments
2. Create project repository structure
3. Begin Phase 1 implementation
4. Weekly progress reviews


### Reference

- [First DeepResearch to plan](https://chatgpt.com/share/685eba1f-b838-800f-9663-06246c50aa1b)