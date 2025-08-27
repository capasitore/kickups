import Foundation
import AVFoundation
import Vision
import Combine

class KickDetector: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var kickCount: Int = 0
    @Published var isInCooldown: Bool = false
    @Published var distanceHistory: [Double] = []
    @Published var isDetectionEnabled: Bool = true
    
    // MARK: - Configuration
    @Published var contactThreshold: Double = 70.0
    @Published var cooldownFrames: Int = 13
    @Published var useAnkleDetection: Bool = true
    @Published var useFootDetection: Bool = true
    
    // MARK: - Private Properties
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let detectionQueue = DispatchQueue(label: "detectionQueue", qos: .userInteractive)
    
    private var poseDetector = PoseDetector()
    private var ballDetector = BallDetector()
    
    private var cooldownCounter: Int = 0
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // MARK: - Pose landmarks indices (following MediaPipe convention)
    private let ankleIndices = [27, 28] // Left ankle, Right ankle
    private let footIndices = [31, 32]  // Left foot, Right foot
    
    override init() {
        super.init()
        setupNotifications()
    }
    
    deinit {
        stopCapture()
    }
    
    // MARK: - Public Methods
    func setupCamera(previewView: CameraPreviewView) {
        sessionQueue.async { [weak self] in
            self?.setupCaptureSession()
            
            DispatchQueue.main.async {
                previewView.previewLayer.session = self?.captureSession
                previewView.previewLayer.videoGravity = .resizeAspectFill
                self?.previewLayer = previewView.previewLayer
            }
            
            self?.startCapture()
        }
    }
    
    func reset() {
        kickCount = 0
        cooldownCounter = 0
        isInCooldown = false
        distanceHistory.removeAll()
    }
    
    func startCapture() {
        sessionQueue.async { [weak self] in
            if self?.captureSession.isRunning == false {
                self?.captureSession.startRunning()
            }
        }
    }
    
    func stopCapture() {
        sessionQueue.async { [weak self] in
            if self?.captureSession.isRunning == true {
                self?.captureSession.stopRunning()
            }
        }
    }
    
    // MARK: - Private Methods
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        stopCapture()
    }
    
    @objc private func appWillEnterForeground() {
        startCapture()
    }
    
    private func setupCaptureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        
        // Add camera input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let cameraInput = try? AVCaptureDeviceInput(device: camera),
              captureSession.canAddInput(cameraInput) else {
            print("Failed to setup camera input")
            captureSession.commitConfiguration()
            return
        }
        
        captureSession.addInput(cameraInput)
        
        // Setup video output
        videoOutput.setSampleBufferDelegate(self, queue: detectionQueue)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        // Configure video orientation
        if let connection = videoOutput.connection(with: .video) {
            connection.videoOrientation = .portrait
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = false
            }
        }
        
        captureSession.commitConfiguration()
    }
    
    private func processFrame(_ pixelBuffer: CVPixelBuffer) {
        guard isDetectionEnabled else { return }
        
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Update cooldown
        if cooldownCounter > 0 {
            cooldownCounter -= 1
            DispatchQueue.main.async {
                self.isInCooldown = self.cooldownCounter > 0
            }
        }
        
        // Detect pose and ball simultaneously
        let group = DispatchGroup()
        var posePoints: [CGPoint] = []
        var ballPosition: CGPoint?
        
        // Detect pose
        group.enter()
        poseDetector.detectPose(in: image) { points in
            posePoints = points
            group.leave()
        }
        
        // Detect ball
        group.enter()
        ballDetector.detectBall(in: image) { position in
            ballPosition = position
            group.leave()
        }
        
        group.notify(queue: detectionQueue) { [weak self] in
            self?.processDetections(posePoints: posePoints, ballPosition: ballPosition)
        }
    }
    
    private func processDetections(posePoints: [CGPoint], ballPosition: CGPoint?) {
        guard let ballPos = ballPosition, !posePoints.isEmpty else {
            DispatchQueue.main.async {
                self.distanceHistory.append(200.0) // Max distance when no detection
            }
            return
        }
        
        var minDistance: Double = Double.infinity
        
        // Check contact points based on settings
        var contactIndices: [Int] = []
        if useAnkleDetection {
            contactIndices.append(contentsOf: ankleIndices)
        }
        if useFootDetection {
            contactIndices.append(contentsOf: footIndices)
        }
        
        // Calculate distances to all relevant landmarks
        for index in contactIndices {
            if index < posePoints.count {
                let landmarkPos = posePoints[index]
                let distance = sqrt(pow(ballPos.x - landmarkPos.x, 2) + pow(ballPos.y - landmarkPos.y, 2))
                minDistance = min(minDistance, distance)
            }
        }
        
        // Convert to pixel distance (approximation)
        let pixelDistance = minDistance * 1000 // Scale factor to match original Python implementation
        
        // Check for kick detection
        if pixelDistance < contactThreshold && cooldownCounter == 0 {
            cooldownCounter = cooldownFrames
            
            DispatchQueue.main.async {
                self.kickCount += 1
                self.isInCooldown = true
            }
        }
        
        DispatchQueue.main.async {
            self.distanceHistory.append(pixelDistance)
            
            // Keep only recent history
            if self.distanceHistory.count > 200 {
                self.distanceHistory.removeFirst()
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension KickDetector: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        processFrame(pixelBuffer)
    }
}