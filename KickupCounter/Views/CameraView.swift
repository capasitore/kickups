import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    let kickDetector: KickDetector
    
    func makeUIView(context: Context) -> CameraPreviewView {
        let previewView = CameraPreviewView()
        kickDetector.setupCamera(previewView: previewView)
        return previewView
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        // Updates handled by KickDetector
    }
}

class CameraPreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}