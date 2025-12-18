import AVFoundation
import Combine
import SwiftUI

struct CameraView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var cameraController = CameraController()
    
    @State private var isCapturing = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            CameraPreviewView(session: cameraController.captureSession)
                .ignoresSafeArea()
            
            VStack {
                topBar
                
                Spacer()
                
                bottomControls
            }
            
            if isCapturing {
                Color.white
                    .ignoresSafeArea()
                    .opacity(0.3)
                    .animation(.easeOut(duration: 0.1), value: isCapturing)
            }
        }
        .onAppear {
            cameraController.resetCapturedImage()
            cameraController.startSession()
            print("[CameraView] Camera appeared, session starting")
        }
        .onDisappear {
            cameraController.stopSession()
            print("[CameraView] Camera disappeared, session stopped")
        }
        .onChange(of: cameraController.capturedImage) { _, newImage in
            if let image = newImage {
                print("[CameraView] Photo captured, navigating to result")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    appViewModel.navigateToResult(image: image)
                }
            }
        }
    }
    
    private var topBar: some View {
        HStack {
            Button(action: {
                HapticManager.lightImpact()
                appViewModel.navigateBack()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            
            Spacer()
            
            Button(action: {
                HapticManager.lightImpact()
                cameraController.toggleFlash()
            }) {
                Image(systemName: cameraController.flashMode == .on ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(cameraController.flashMode == .on ? .yellow : .white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private var bottomControls: some View {
        HStack {
            Spacer()
            
            Button(action: {
                capturePhoto()
            }) {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 76, height: 76)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 64, height: 64)
                }
            }
            .disabled(isCapturing)
            
            Spacer()
        }
        .padding(.bottom, 40)
    }
    
    private func capturePhoto() {
        isCapturing = true
        HapticManager.mediumImpact()
        
        cameraController.capturePhoto()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isCapturing = false
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.session = session
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.session = session
    }
}

final class CameraPreviewUIView: UIView {
    var session: AVCaptureSession? {
        didSet {
            guard let session = session else { return }
            (layer as? AVCaptureVideoPreviewLayer)?.session = session
        }
    }
    
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        (layer as? AVCaptureVideoPreviewLayer)?.videoGravity = .resizeAspectFill
    }
}

@MainActor
final class CameraController: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var isSessionRunning = false
    
    let captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var currentDevice: AVCaptureDevice?
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            captureSession.commitConfiguration()
            return
        }
        
        currentDevice = videoDevice
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
        } catch {
            print("Error creating video input: \(error)")
            captureSession.commitConfiguration()
            return
        }
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        }
        
        captureSession.commitConfiguration()
    }
    
    func startSession() {
        guard !captureSession.isRunning else { return }
        
        Task.detached(priority: .userInitiated) { [weak self] in
            self?.captureSession.startRunning()
            
            await MainActor.run {
                self?.isSessionRunning = true
            }
        }
    }
    
    func stopSession() {
        guard captureSession.isRunning else { return }
        
        Task.detached(priority: .userInitiated) { [weak self] in
            self?.captureSession.stopRunning()
            
            await MainActor.run {
                self?.isSessionRunning = false
            }
        }
    }
    
    func toggleFlash() {
        flashMode = flashMode == .off ? .on : .off
    }
    
    func resetCapturedImage() {
        capturedImage = nil
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        
        if let device = currentDevice, device.hasFlash {
            settings.flashMode = flashMode
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("[CameraController] Error capturing photo: \(error)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("[CameraController] Failed to get photo data representation")
            return
        }
        
        guard let image = UIImage(data: imageData) else {
            print("[CameraController] Failed to create UIImage from data")
            return
        }
        
        print("[CameraController] Photo captured successfully, size: \(image.size)")
        
        Task { @MainActor in
            self.capturedImage = image
        }
    }
}

#Preview {
    CameraView()
        .environmentObject(AppViewModel())
}
