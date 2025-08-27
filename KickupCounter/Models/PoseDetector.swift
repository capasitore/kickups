import Foundation
import Vision
import CoreImage

class PoseDetector {
    private var poseRequest: VNDetectHumanBodyPoseRequest
    
    init() {
        poseRequest = VNDetectHumanBodyPoseRequest()
        poseRequest.revision = VNDetectHumanBodyPoseRequestRevision1
    }
    
    func detectPose(in image: CIImage, completion: @escaping ([CGPoint]) -> Void) {
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        
        do {
            try handler.perform([poseRequest])
            
            guard let observation = poseRequest.results?.first else {
                completion([])
                return
            }
            
            let landmarks = extractLandmarks(from: observation)
            completion(landmarks)
            
        } catch {
            print("Pose detection failed: \(error)")
            completion([])
        }
    }
    
    private func extractLandmarks(from observation: VNHumanBodyPoseObservation) -> [CGPoint] {
        // Initialize array with 33 points to match MediaPipe format
        var landmarks = Array(repeating: CGPoint.zero, count: 33)
        
        do {
            // Map Vision landmarks to MediaPipe-like indices
            let recognizedPoints = try observation.recognizedPoints(.all)
            
            // Map key body points to MediaPipe indices
            // Note: Vision framework provides different landmarks than MediaPipe
            // This is an approximation to maintain compatibility
            
            // Ankles (indices 27, 28 in MediaPipe)
            if let leftAnkle = recognizedPoints[.leftAnkle],
               leftAnkle.confidence > 0.5 {
                landmarks[27] = leftAnkle.location
            }
            
            if let rightAnkle = recognizedPoints[.rightAnkle],
               rightAnkle.confidence > 0.5 {
                landmarks[28] = rightAnkle.location
            }
            
            // For foot points (indices 31, 32), we'll approximate using ankle positions
            // since Vision doesn't provide exact foot landmark points
            if let leftAnkle = recognizedPoints[.leftAnkle],
               leftAnkle.confidence > 0.5 {
                // Approximate foot position slightly below ankle
                landmarks[31] = CGPoint(x: leftAnkle.location.x, y: leftAnkle.location.y - 0.05)
            }
            
            if let rightAnkle = recognizedPoints[.rightAnkle],
               rightAnkle.confidence > 0.5 {
                landmarks[32] = CGPoint(x: rightAnkle.location.x, y: rightAnkle.location.y - 0.05)
            }
            
            // Knees (indices 25, 26 in MediaPipe)
            if let leftKnee = recognizedPoints[.leftKnee],
               leftKnee.confidence > 0.5 {
                landmarks[25] = leftKnee.location
            }
            
            if let rightKnee = recognizedPoints[.rightKnee],
               rightKnee.confidence > 0.5 {
                landmarks[26] = rightKnee.location
            }
            
            // Additional key points for completeness
            if let nose = recognizedPoints[.nose],
               nose.confidence > 0.5 {
                landmarks[0] = nose.location
            }
            
            if let neck = recognizedPoints[.neck],
               neck.confidence > 0.5 {
                landmarks[1] = neck.location
            }
            
            // Shoulders
            if let leftShoulder = recognizedPoints[.leftShoulder],
               leftShoulder.confidence > 0.5 {
                landmarks[11] = leftShoulder.location
            }
            
            if let rightShoulder = recognizedPoints[.rightShoulder],
               rightShoulder.confidence > 0.5 {
                landmarks[12] = rightShoulder.location
            }
            
            // Elbows
            if let leftElbow = recognizedPoints[.leftElbow],
               leftElbow.confidence > 0.5 {
                landmarks[13] = leftElbow.location
            }
            
            if let rightElbow = recognizedPoints[.rightElbow],
               rightElbow.confidence > 0.5 {
                landmarks[14] = rightElbow.location
            }
            
            // Wrists
            if let leftWrist = recognizedPoints[.leftWrist],
               leftWrist.confidence > 0.5 {
                landmarks[15] = leftWrist.location
            }
            
            if let rightWrist = recognizedPoints[.rightWrist],
               rightWrist.confidence > 0.5 {
                landmarks[16] = rightWrist.location
            }
            
            // Hips
            if let leftHip = recognizedPoints[.leftHip],
               leftHip.confidence > 0.5 {
                landmarks[23] = leftHip.location
            }
            
            if let rightHip = recognizedPoints[.rightHip],
               rightHip.confidence > 0.5 {
                landmarks[24] = rightHip.location
            }
            
        } catch {
            print("Failed to extract pose landmarks: \(error)")
        }
        
        return landmarks
    }
    
    // Helper method to convert normalized coordinates to pixel coordinates
    func convertToPixelCoordinates(_ landmarks: [CGPoint], imageSize: CGSize) -> [CGPoint] {
        return landmarks.map { point in
            CGPoint(
                x: point.x * imageSize.width,
                y: (1.0 - point.y) * imageSize.height // Flip Y coordinate
            )
        }
    }
    
    // Helper method to calculate distance between two points
    func calculateDistance(_ point1: CGPoint, _ point2: CGPoint) -> Double {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt(Double(dx * dx + dy * dy))
    }
}