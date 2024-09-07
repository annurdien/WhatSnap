import UIKit
import Vision
import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    @Binding var detectedPhoneNumber: String?
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let cameraViewController = CameraViewController()
        cameraViewController.detectedPhoneNumber = $detectedPhoneNumber
        return cameraViewController
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

class CameraViewController: UIViewController {
    var detectedPhoneNumber: Binding<String?>?
    private var captureSession: AVCaptureSession?
    private var textDetectionRequest = VNRecognizeTextRequest()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var videoDevice: AVCaptureDevice!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupVision()
    }
    
    private func setupCamera() {
        captureSession                  = AVCaptureSession()
        guard let captureSession        = captureSession else { return }
        captureSession.sessionPreset    = .high
        videoDevice                     = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        
        guard 
        let videoDevice                 = videoDevice,
        let videoDeviceInput            = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        
        if captureSession.canAddInput(videoDeviceInput) {
            captureSession.addInput(videoDeviceInput)
        }
        
        let videoOutput                 = AVCaptureVideoDataOutput()
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        previewLayer                    = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity       = .resizeAspectFill
        previewLayer.frame              = view.bounds
        
        view.layer.addSublayer(previewLayer)
        view.addGestureRecognizer(focusGesture)
        
        DispatchQueue.global(qos: .background).async {
            captureSession.startRunning()
        }
    }
    
    lazy var focusGesture: UITapGestureRecognizer = {
        let instance                        = UITapGestureRecognizer(target: self, action: #selector(tapToFocus))
        instance.cancelsTouchesInView       = false
        instance.numberOfTapsRequired       = 1
        instance.numberOfTouchesRequired    = 1
        return instance
    }()
    
    @objc func tapToFocus(_ gesture: UITapGestureRecognizer) {
        guard let previewLayer = previewLayer else {
            print("Expected a previewLayer")
            return
        }
        guard let device = videoDevice else {
            print("Expected a device")
            return
        }
        
        
        let touchPoint: CGPoint                     = gesture.location(in: view)
        let convertedPoint: CGPoint                 = previewLayer.captureDevicePointConverted(fromLayerPoint: touchPoint)
        if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus) {
            do {
                try device.lockForConfiguration()
                device.focusPointOfInterest         = convertedPoint
                device.focusMode                    = AVCaptureDevice.FocusMode.autoFocus
                device.unlockForConfiguration()
            } catch {
                print("unable to focus")
            }
        }
        let location                    = gesture.location(in: view)
        let x                           = location.x - 125
        let y                           = location.y - 125
        let lineView                    = DrawSquare(frame: CGRect(x: x, y: y, width: 250, height: 250))
        lineView.backgroundColor        = UIColor.clear
        lineView.alpha                  = 0.9
        view.addSubview(lineView)
        
        DrawSquare.animate(withDuration: 1, animations: {
            lineView.alpha = 1
        }) { (success) in
            lineView.alpha = 0
        }
        
    }
    
    private func setupVision() {
        textDetectionRequest = VNRecognizeTextRequest { [weak self] (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else { return }
            
            for observation in observations {
                let topCandidate = observation.topCandidates(1)
                if let recognizedText = topCandidate.first?.string {
                    // Check if the detected text is a valid phone number (simple regex pattern)
                    if recognizedText.isValidPhoneNumber() == true {
                        DispatchQueue.main.async {
                            self?.detectedPhoneNumber?.wrappedValue = recognizedText
                        }
                    }
                }
            }
        }
        textDetectionRequest.recognitionLevel = .accurate
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let requestOptions: [VNImageOption: Any] = [:]
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: requestOptions)
        try? imageRequestHandler.perform([textDetectionRequest])
    }
}
