import AVFoundation
import Combine
import Photos
import SwiftUI

@MainActor
final class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published private(set) var cameraStatus: AppPermissionStatus = .notDetermined
    @Published private(set) var photoLibraryStatus: AppPermissionStatus = .notDetermined
    
    var hasAnyPermission: Bool {
        cameraStatus.isGranted || photoLibraryStatus.isGranted
    }
    
    var hasCameraPermission: Bool {
        cameraStatus.isGranted
    }
    
    var hasPhotoLibraryPermission: Bool {
        photoLibraryStatus.isGranted
    }
    
    private init() {
        checkCurrentPermissions()
    }
    
    func checkCurrentPermissions() {
        updateCameraStatus()
        updatePhotoLibraryStatus()
    }
    
    private func updateCameraStatus() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        cameraStatus = mapAVAuthorizationStatus(status)
    }
    
    private func updatePhotoLibraryStatus() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        photoLibraryStatus = mapPHAuthorizationStatus(status)
    }
    
    private func mapAVAuthorizationStatus(_ status: AVAuthorizationStatus) -> AppPermissionStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .notDetermined
        }
    }
    
    private func mapPHAuthorizationStatus(_ status: PHAuthorizationStatus) -> AppPermissionStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .authorized, .limited:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .notDetermined
        }
    }
    
    func requestCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            updateCameraStatus()
            return granted
        case .authorized:
            updateCameraStatus()
            return true
        default:
            updateCameraStatus()
            return false
        }
    }
    
    func requestPhotoLibraryPermission() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            updatePhotoLibraryStatus()
            return newStatus == .authorized || newStatus == .limited
        case .authorized, .limited:
            updatePhotoLibraryStatus()
            return true
        default:
            updatePhotoLibraryStatus()
            return false
        }
    }
    
    func requestAllPermissions() async -> Bool {
        _ = await requestCameraPermission()
        _ = await requestPhotoLibraryPermission()
        return hasAnyPermission
    }
    
    func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
}
