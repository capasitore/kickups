# iOS App Testing & Core ML Integration Guide

## Testing the iOS App

### Requirements
- **Xcode 15.0+**: Latest version of Xcode
- **iOS Device**: iPhone or iPad running iOS 17.0+
- **Physical Device**: Simulator won't work due to camera requirement
- **Apple Developer Account**: For device testing (free account works)

### Testing Steps

1. **Open Project**
   ```bash
   cd KickupCounter
   open KickupCounter.xcodeproj
   ```

2. **Configure Signing**
   - Select your Apple Developer account in Xcode
   - Choose your team for code signing
   - Ensure bundle identifier is unique

3. **Connect Device**
   - Connect iPhone/iPad via USB
   - Trust the device in Xcode
   - Select device as target

4. **Build and Run**
   - Press Cmd+R or click the Run button
   - Allow camera permissions when prompted
   - Test kick-up detection with a ball

### Expected Functionality
- ✅ Camera preview displays
- ✅ Pose detection shows body landmarks
- ✅ Ball detection (currently using heuristic circle detection)
- ✅ Kick counting when ball approaches foot
- ✅ Real-time distance visualization
- ✅ Settings adjustment works

## Integrating Custom Core ML Model

### Step 1: Convert YOLO to Core ML

Create a Python script to convert your trained YOLO model:

```python
# convert_model.py
import coremltools as ct
from ultralytics import YOLO
import torch

def convert_yolo_to_coreml():
    # Load your trained YOLO model
    model = YOLO('path/to/your/ball_model.pt')
    
    # Export to Core ML with optimizations
    success = model.export(
        format='coreml',
        nms=True,           # Include NMS in model
        half=False,         # Full precision
        int8=False,         # No quantization (better accuracy)
        dynamic=False,      # Fixed input size
        simplify=True       # Optimize for mobile
    )
    
    print(f"Core ML export successful: {success}")
    return success

if __name__ == "__main__":
    convert_yolo_to_coreml()
```

### Step 2: Add Model to Xcode

1. **Drag Model File**
   - Drag the generated `.mlmodel` file into Xcode
   - Add to KickupCounter target
   - Verify in project navigator

2. **Inspect Model**
   - Click on the model in Xcode
   - Check input/output specifications
   - Note the model class name

### Step 3: Update BallDetector.swift

Replace the placeholder implementation:

```swift
// In BallDetector.swift
import CoreML

class BallDetector {
    private var ballModel: MLModel?
    
    init() {
        loadCoreMLModel()
    }
    
    private func loadCoreMLModel() {
        do {
            // Replace "YourBallModel" with actual model name
            guard let modelURL = Bundle.main.url(forResource: "YourBallModel", withExtension: "mlmodelc") else {
                print("Core ML model not found")
                return
            }
            
            ballModel = try MLModel(contentsOf: modelURL)
            print("Core ML model loaded successfully")
        } catch {
            print("Failed to load Core ML model: \(error)")
        }
    }
    
    func detectBall(in image: CIImage, completion: @escaping (CGPoint?) -> Void) {
        guard let model = ballModel else {
            // Fallback to heuristic detection
            detectBallUsingColorHeuristics(in: image, completion: completion)
            return
        }
        
        do {
            let visionModel = try VNCoreMLModel(for: model)
            let request = VNCoreMLRequest(model: visionModel) { request, error in
                self.processCoreMLResults(request, error, completion)
            }
            
            let handler = VNImageRequestHandler(ciImage: image, options: [:])
            try handler.perform([request])
        } catch {
            print("Core ML inference failed: \(error)")
            completion(nil)
        }
    }
    
    private func processCoreMLResults(_ request: VNRequest, _ error: Error?, _ completion: @escaping (CGPoint?) -> Void) {
        guard error == nil,
              let observations = request.results as? [VNRecognizedObjectObservation] else {
            completion(nil)
            return
        }
        
        // Filter for ball detections with high confidence
        let ballDetections = observations.filter { observation in
            observation.confidence > 0.5 && 
            observation.labels.contains { $0.identifier.contains("ball") }
        }
        
        // Return the most confident detection
        if let bestDetection = ballDetections.max(by: { $0.confidence < $1.confidence }) {
            let centerPoint = CGPoint(
                x: bestDetection.boundingBox.midX,
                y: bestDetection.boundingBox.midY
            )
            completion(centerPoint)
        } else {
            completion(nil)
        }
    }
}
```

## Performance Optimization

### Model Optimization
```python
# When exporting, use these optimizations:
model.export(
    format='coreml',
    nms=True,
    half=True,      # Use half precision for speed
    int8=True,      # Quantize to INT8 for smaller size
    dynamic=False,  # Fixed input size is faster
    optimize=True   # Additional optimizations
)
```

### App Performance Tips

1. **Frame Rate Control**
   ```swift
   // In KickDetector.swift, add frame skipping
   private var frameSkipCounter = 0
   private let processEveryNthFrame = 2  // Process every 2nd frame
   
   func captureOutput(...) {
       frameSkipCounter += 1
       guard frameSkipCounter >= processEveryNthFrame else { return }
       frameSkipCounter = 0
       
       // Process frame...
   }
   ```

2. **Memory Management**
   ```swift
   // Limit history size
   DispatchQueue.main.async {
       self.distanceHistory.append(pixelDistance)
       if self.distanceHistory.count > 100 {
           self.distanceHistory.removeFirst(self.distanceHistory.count - 100)
       }
   }
   ```

## Troubleshooting

### Common Issues

**Camera Permission Denied**
- Check Info.plist has `NSCameraUsageDescription`
- Reset privacy settings in iOS Settings

**Model Loading Fails**
- Verify `.mlmodel` file is in app bundle
- Check model compatibility with iOS version
- Ensure model was compiled correctly

**Poor Detection Performance**
- Reduce input resolution
- Implement frame skipping
- Use quantized model (INT8)
- Process fewer frames per second

**App Crashes**
- Check memory usage in Instruments
- Verify all delegates are properly managed
- Test on different iOS versions

### Debug Tools

1. **Xcode Instruments**
   - Monitor CPU and memory usage
   - Check for memory leaks
   - Profile Core ML performance

2. **Console Logs**
   - Enable detailed logging
   - Monitor detection confidence scores
   - Track frame processing times

3. **On-Device Testing**
   - Test on older devices
   - Verify performance across iOS versions
   - Check battery impact

## Next Steps

1. **Train Custom Model**: Create a dataset and train YOLO specifically for ball detection
2. **Optimize Performance**: Profile and optimize for your target devices
3. **Add Features**: Implement additional features like session recording
4. **App Store**: Prepare for App Store submission with proper metadata

The iOS app is now ready for testing and can be enhanced with a custom Core ML model for improved ball detection accuracy!