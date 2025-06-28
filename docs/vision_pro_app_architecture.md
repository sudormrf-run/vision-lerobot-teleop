# Vision Pro App Architecture Document

## Official Apple Documentation References

### Core Documentation
- [visionOS Overview](https://developer.apple.com/visionos/) - Main developer portal for visionOS
- [visionOS Documentation](https://developer.apple.com/documentation/visionos) - Comprehensive API reference
- [Get Started with visionOS](https://developer.apple.com/visionos/get-started/) - Official getting started guide

### Hand Tracking & ARKit
- [ARKit in visionOS](https://developer.apple.com/documentation/arkit/arkit-in-visionos) - ARKit framework for spatial computing
- [Tracking and visualizing hand movement](https://developer.apple.com/documentation/visionos/tracking-and-visualizing-hand-movement) - Hand tracking implementation guide
- [Bringing your ARKit app to visionOS](https://developer.apple.com/documentation/visionos/bringing-your-arkit-app-to-visionos/) - Migration guide
- [Exploring object tracking with ARKit](https://developer.apple.com/documentation/visionOS/exploring_object_tracking_with_arkit) - Advanced tracking techniques

### Framework Documentation
- [RealityKit Documentation](https://developer.apple.com/documentation/realitykit) - 3D rendering engine
- [SwiftUI for visionOS](https://developer.apple.com/documentation/visionos) - UI framework integration
- [Vision Framework](https://developer.apple.com/documentation/vision/) - Computer vision APIs

### Development Resources
- [Construct an immersive environment](https://developer.apple.com/documentation/realitykit/construct-an-immersive-environment-for-visionos) - Building immersive spaces
- [Designing with Reality Composer Pro](https://developer.apple.com/documentation/visionos/designing-realitykit-content-with-reality-composer-pro) - Content creation
- [Swift Splash Sample](https://developer.apple.com/documentation/visionos/swift-splash) - Interactive RealityKit example

### Video Resources
- [Meet ARKit for spatial computing - WWDC23](https://developer.apple.com/videos/play/wwdc2023/10082/) - Hand tracking explained from 15:05
- [Discover RealityKit APIs - WWDC24](https://developer.apple.com/videos/play/wwdc2024/10103/) - Latest RealityKit features
- [Explore object tracking - WWDC24](https://developer.apple.com/videos/play/wwdc2024/10101/) - Advanced tracking techniques

## Hand-Robot Calibration Process

### Overview
To enable accurate teleoperation, we need to establish a mapping between the Vision Pro's hand tracking coordinate system and the robot's workspace coordinate system. This calibration process will ensure that hand movements are accurately translated to robot movements.

### Calibration Requirements

#### 1. Coordinate System Alignment
- **Vision Pro Coordinate System**: World-space coordinates with origin at ARKit session start
- **Robot Coordinate System**: Robot base frame with its own origin and orientation
- **Challenge**: Need to establish transformation matrix between these two coordinate systems

#### 2. Workspace Mapping
- Define the robot's reachable workspace boundaries
- Map the user's comfortable hand movement range to robot workspace
- Handle scaling factors between human and robot arm lengths

#### 3. Reference Point Calibration
- User will need to position their hand at specific calibration points
- These points should correspond to known positions in robot workspace
- Minimum 3-4 points needed for accurate calibration

### Proposed Calibration Process

#### Phase 1: Initial Setup
1. Robot moves to predefined calibration poses
2. User interface displays visual markers at these positions
3. User aligns their hand with each marker position
4. System records hand coordinates at each calibration point

#### Phase 2: Coordinate Transform Calculation
1. Calculate transformation matrix from recorded point pairs
2. Determine scaling factors for movement range
3. Compute offset and rotation between coordinate systems

#### Phase 3: Validation
1. User performs test movements
2. System shows both hand position and predicted robot position
3. User can fine-tune calibration if needed

### Technical Implementation Notes

#### Data Structures Needed
- Calibration point pairs (Vision Pro coords ↔ Robot coords)
- Transformation matrix (4x4 homogeneous transform)
- Scaling factors and workspace limits
- Calibration status and accuracy metrics

#### Calibration Storage
- Save calibration data for future sessions
- Allow multiple calibration profiles
- Quick recalibration option for session start

### Future Considerations
- Auto-calibration using visual markers on robot
- Dynamic calibration adjustment during operation
- Safety boundaries and movement constraints
- Haptic feedback for workspace limits

