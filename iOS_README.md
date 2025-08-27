# iOS Kick-up Counter App

An iOS application that performs real-time kick-up counting entirely on-device using Apple's Vision framework and Core ML.

## Features

### 🎯 Core Functionality
- **Real-time Ball Detection**: Uses Vision framework and Core ML for on-device ball detection
- **Pose Estimation**: Leverages Apple's Vision framework for human pose detection
- **Kick Counting**: Automatically counts kick-ups based on ball-to-foot proximity
- **Live Visualization**: Real-time distance plotting and visual feedback
- **On-Device Processing**: Everything runs locally - no cloud processing required

### 📱 iOS-Specific Features
- **Native SwiftUI Interface**: Modern, responsive UI built with SwiftUI
- **Camera Integration**: Seamless integration with iOS camera using AVFoundation
- **Performance Optimized**: Optimized for real-time processing on iOS devices
- **Settings Configuration**: Adjustable thresholds and detection parameters
- **Background Handling**: Proper camera session management for app lifecycle

## Technical Implementation

### 🏗️ Architecture
- **SwiftUI**: Modern declarative UI framework
- **Vision Framework**: Apple's computer vision framework for pose detection
- **Core ML**: On-device machine learning for object detection
- **AVFoundation**: Camera capture and video processing
- **Combine**: Reactive programming for data flow

### 🔍 Detection Pipeline
1. **Camera Capture**: AVFoundation captures video frames from device camera
2. **Pose Detection**: Vision framework detects human body landmarks
3. **Ball Detection**: Core ML model (or heuristic detection) identifies ball position
4. **Distance Calculation**: Computes distance between ball and foot landmarks
5. **Kick Detection**: Triggers count when distance falls below threshold
6. **Cooldown Management**: Prevents double-counting with configurable cooldown

### 📊 Key Components

#### Models
- `KickDetector`: Main coordinator handling detection logic and state management
- `PoseDetector`: Wrapper for Vision framework pose detection
- `BallDetector`: Ball detection using Core ML or heuristic methods

#### Views
- `ContentView`: Main app interface with kick counter and controls
- `CameraView`: Camera preview integration with AVFoundation
- `DistancePlotView`: Real-time distance visualization

## Setup Instructions

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- Physical iOS device with camera (required for testing)

### Build and Run
1. Open `KickupCounter.xcodeproj` in Xcode
2. Select your target device (simulator won't work due to camera requirement)
3. Build and run the project

### Configuration
The app includes configurable parameters:
- **Contact Threshold**: Distance threshold for kick detection (default: 70px)
- **Cooldown Frames**: Frames to wait between kick detections (default: 13)
- **Contact Points**: Choose between ankle and/or foot detection

## Core ML Model Integration

### Current Implementation
The app currently uses Vision framework's circle detection as a placeholder for ball detection.

### Custom YOLO Model Integration
To use a custom Core ML model for improved ball detection:

1. **Convert YOLO model to Core ML**:
```python
import coremltools as ct
from ultralytics import YOLO

# Load your trained YOLO model
model = YOLO('path/to/your/yolo_ball_model.pt')

# Export to Core ML format
model.export(format='coreml', nms=True, half=False)
```

2. **Add model to Xcode project**:
   - Drag the `.mlmodel` file into your Xcode project
   - Ensure it's added to the target

3. **Update BallDetector.swift**:
   - Implement `detectBallUsingCoreMLModel` method
   - Load your custom Core ML model
   - Parse YOLO output for ball detections

## Performance Considerations

### Optimization Features
- **Efficient Frame Processing**: Processes frames on background queue
- **Smart Cooldown**: Prevents unnecessary processing during cooldown
- **Memory Management**: Limits history storage and cleans up resources
- **Battery Optimization**: Pauses detection when app goes to background

### Device Requirements
- **Minimum**: iPhone 12 / iPad (8th generation) for optimal performance
- **Recommended**: iPhone 14 Pro or later for best performance
- **Camera**: Rear-facing camera required for detection

## Privacy and Security

### On-Device Processing
- All computer vision processing happens locally
- No video data is sent to external servers
- Camera access requested only when needed
- Automatic session cleanup on app backgrounding

### Permissions
- **Camera Access**: Required for real-time video processing
- **No Network Access**: App works entirely offline

## Comparison with Python Version

| Feature | Python Version | iOS Version |
|---------|----------------|-------------|
| **Ball Detection** | YOLO v11 | Core ML / Vision Framework |
| **Pose Detection** | cvzone/MediaPipe | Apple Vision Framework |
| **Platform** | Desktop/Server | iOS Mobile |
| **Performance** | High (GPU dependent) | Optimized for mobile |
| **Dependencies** | OpenCV, PyTorch, etc. | Native iOS frameworks |
| **Deployment** | Local installation | App Store distribution |

## Future Enhancements

### Planned Features
- [ ] Export kick counting sessions
- [ ] Multiple person detection
- [ ] Custom training data collection
- [ ] Apple Watch integration
- [ ] ARKit overlay features
- [ ] Performance analytics

### Technical Improvements
- [ ] Custom Core ML model integration
- [ ] Metal Performance Shaders optimization
- [ ] Improved ball detection accuracy
- [ ] Multi-threading optimizations
- [ ] Advanced filtering algorithms

## Development Notes

### Project Structure
```
KickupCounter/
├── KickupCounterApp.swift       # App entry point
├── Views/
│   ├── ContentView.swift        # Main interface
│   ├── CameraView.swift         # Camera integration
│   └── DistancePlotView.swift   # Visualization
├── Models/
│   ├── KickDetector.swift       # Main detection logic
│   ├── PoseDetector.swift       # Pose detection wrapper
│   └── BallDetector.swift       # Ball detection logic
└── Resources/
    ├── Assets.xcassets          # App assets
    └── Info.plist              # App configuration
```

### Key Technologies
- **SwiftUI**: Declarative UI framework
- **Vision**: Apple's computer vision framework
- **AVFoundation**: Audio/video capture and processing
- **Core ML**: On-device machine learning
- **Combine**: Reactive programming framework

## License

This iOS implementation maintains the same MIT License as the original Python project.

---

*Built with ❤️ for iOS using native Apple frameworks*