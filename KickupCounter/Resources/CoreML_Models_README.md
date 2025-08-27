# Core ML Model Integration

This directory is where you would place your Core ML models for enhanced ball detection.

## Adding a Custom Ball Detection Model

### Step 1: Convert YOLO Model to Core ML

```python
# requirements: coremltools, ultralytics
import coremltools as ct
from ultralytics import YOLO

# Load your trained YOLO model (should be trained specifically for ball detection)
model = YOLO('path/to/your/ball_detection_model.pt')

# Export to Core ML format
model.export(format='coreml', nms=True, half=False, int8=False)
```

### Step 2: Add Model to Xcode Project

1. Drag the generated `.mlmodel` file into your Xcode project
2. Make sure it's added to the app target
3. Xcode will automatically generate Swift classes for the model

### Step 3: Update BallDetector.swift

Replace the placeholder `detectBallUsingCoreMLModel` method with actual Core ML inference:

```swift
import CoreML

private func detectBallUsingCoreMLModel(in image: CIImage, completion: @escaping (CGPoint?) -> Void) {
    guard let model = try? YOLOBallDetector(configuration: MLModelConfiguration()) else {
        fallback to heuristic detection
        detectBallUsingColorHeuristics(in: image, completion: completion)
        return
    }
    
    let request = VNCoreMLRequest(model: VNCoreMLModel(for: model.model)) { request, error in
        guard let results = request.results as? [VNRecognizedObjectObservation] else {
            completion(nil)
            return
        }
        
        // Filter for ball detections (class index depends on your training)
        let ballDetections = results.filter { observation in
            observation.labels.first?.identifier == "ball" && observation.confidence > 0.5
        }
        
        // Return the most confident detection center
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
    
    let handler = VNImageRequestHandler(ciImage: image, options: [:])
    do {
        try handler.perform([request])
    } catch {
        print("Core ML inference failed: \(error)")
        completion(nil)
    }
}
```

## Model Performance Considerations

- **Model Size**: Keep models under 50MB for optimal loading time
- **Quantization**: Use INT8 quantization for better performance on device
- **Input Resolution**: Match your model's expected input size with camera resolution
- **Inference Speed**: Aim for <50ms inference time for real-time performance

## Recommended Training Data

For best results, train your YOLO model with:
- Various ball types (soccer, basketball, tennis, etc.)
- Different lighting conditions
- Various backgrounds and environments
- Multiple camera angles and distances
- Motion blur scenarios

Place your trained `.mlmodel` files in this directory and update the import statements in the Swift code accordingly.