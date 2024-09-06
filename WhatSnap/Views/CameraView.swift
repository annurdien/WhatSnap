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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupVision()
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        captureSession.sessionPreset = .high

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }

        if captureSession.canAddInput(videoDeviceInput) {
            captureSession.addInput(videoDeviceInput)
        }

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .background).async {
            captureSession.startRunning()
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
