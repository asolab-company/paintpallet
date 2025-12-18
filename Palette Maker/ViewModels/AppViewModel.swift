import Combine
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published var currentScreen: AppScreen = .splash
    @Published var lastImageSource: ImageSourceType = .camera
    @Published var showingToast: Bool = false
    @Published var toastMessage: String = ""
    @Published var showPhotoPicker: Bool = false
    
    private let permissionManager: PermissionManager
    private let persistenceManager: PersistenceManager
    
    var splashDuration: Double = Double.random(in: 1...5)
    
    init(
        permissionManager: PermissionManager = .shared,
        persistenceManager: PersistenceManager = .shared
    ) {
        self.permissionManager = permissionManager
        self.persistenceManager = persistenceManager
    }
    
    func determineInitialScreen() {
        Task {
            // Use the random splash duration
            let nanoseconds = UInt64(splashDuration * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            
            await MainActor.run {
                withAnimation(.default) {
                    if !persistenceManager.hasSeenOnboarding {
                        currentScreen = .onboarding
                    } else if !permissionManager.hasAnyPermission {
                        currentScreen = .permissionRequest
                    } else {
                        currentScreen = .main
                    }
                }
            }
        }
    }
    
    func completeOnboarding() {
        persistenceManager.completeOnboarding()
        withAnimation(.default) {
            currentScreen = .permissionRequest
        }
    }
    
    func navigateToMain() {
        withAnimation(.default) {
            currentScreen = .main
        }
    }
    
    func navigateToCamera() {
        print("[AppViewModel] Navigating to camera")
        lastImageSource = .camera
        withAnimation(.default) {
            currentScreen = .camera
        }
    }
    
    func navigateToPhotoPicker() {
        print("[AppViewModel] Navigating to photo picker")
        lastImageSource = .photoLibrary
        withAnimation(.default) {
            currentScreen = .photoPicker
        }
    }
    
    func navigateToResult(image: UIImage) {
        print("[AppViewModel] Navigating to result screen with image size: \(image.size)")
        withAnimation(.default) {
            currentScreen = .result(image: image)
        }
    }
    
    func navigateToSettings() {
        print("[AppViewModel] Navigating to settings")
        withAnimation(.default) {
            currentScreen = .settings
        }
    }
    
    func navigateBack() {
        print("[AppViewModel] Navigating back to main")
        withAnimation(.default) {
            currentScreen = .main
        }
    }
    
    func openNewPalette() {
        switch lastImageSource {
        case .camera:
            if permissionManager.hasCameraPermission {
                navigateToCamera()
            } else {
                navigateToPhotoPicker()
            }
        case .photoLibrary:
            if permissionManager.hasPhotoLibraryPermission {
                navigateToPhotoPicker()
            } else {
                navigateToCamera()
            }
        }
    }
    
    func showToast(message: String) {
        toastMessage = message
        withAnimation(.spring(response: 0.3)) {
            showingToast = true
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation(.spring(response: 0.3)) {
                    showingToast = false
                }
            }
        }
    }
}
