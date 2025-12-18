import SwiftUI

struct ContentView: View {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var permissionManager = PermissionManager.shared
    
    var body: some View {
        Group {
            switch appViewModel.currentScreen {
            case .splash:
                SplashScreenView(duration: appViewModel.splashDuration)
                
            case .onboarding:
                OnboardingView()
                
            case .permissionRequest:
                PermissionRequestView()
                
            case .main:
                MainScreenView()
                
            case .camera:
                CameraView()
                
            case .photoPicker:
                MainScreenView()
                
            case .result(let image):
                ResultScreenView(image: image)
                
            case .settings:
                SettingsView()
            }
        }
        .environmentObject(appViewModel)
        .environmentObject(permissionManager)
        .onAppear {
            appViewModel.determineInitialScreen()
        }
    }
}

#Preview {
    ContentView()
}
