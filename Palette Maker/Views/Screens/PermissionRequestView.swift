import SwiftUI

struct PermissionRequestView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var permissionManager: PermissionManager
    
    @State private var isRequesting = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppColors.radialBackground(geometry: geometry)
                    .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button(action: {
                        HapticManager.lightImpact()
                        withAnimation {
                            appViewModel.currentScreen = .onboarding
                        }
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Content
                VStack(spacing: 32) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(AppColors.gradient)
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .shadow(color: AppColors.primaryRed.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    // Text
                    VStack(spacing: 16) {
                        Text("Allow Camera Access")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("To extract colors from photos, we need access to your camera and photo library.\n\nYour photos stay on your device and are never uploaded.")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 32)
                    }
                    
                    // Permission status indicators
                    VStack(spacing: 12) {
                        PermissionStatusRow(
                            icon: "camera.fill",
                            title: "Camera",
                            status: permissionManager.cameraStatus
                        )
                        
                        PermissionStatusRow(
                            icon: "photo.fill",
                            title: "Photo Library",
                            status: permissionManager.photoLibraryStatus
                        )
                    }
                    .padding(.horizontal, 48)
                }
                
                Spacer()
                
                // Grant access button
                VStack(spacing: 16) {
                    GradientButton(
                        title: buttonTitle,
                        icon: buttonIcon
                    ) {
                        handleGrantAccess()
                    }
                    .disabled(isRequesting)
                    .opacity(isRequesting ? 0.7 : 1.0)
                    
                    if permissionManager.cameraStatus == .denied || 
                       permissionManager.photoLibraryStatus == .denied {
                        Text("You can change permissions in Settings")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            }
        }
        .onAppear {
            permissionManager.checkCurrentPermissions()
        }
    }
    
    private var buttonTitle: String {
        if permissionManager.cameraStatus == .denied && 
           permissionManager.photoLibraryStatus == .denied {
            return "Open Settings"
        }
        return "Grant Access"
    }
    
    private var buttonIcon: String {
        if permissionManager.cameraStatus == .denied && 
           permissionManager.photoLibraryStatus == .denied {
            return "gear"
        }
        return "checkmark.shield.fill"
    }
    
    private func handleGrantAccess() {
        // If both permissions are denied, open settings
        if permissionManager.cameraStatus == .denied && 
           permissionManager.photoLibraryStatus == .denied {
            permissionManager.openAppSettings()
            return
        }
        
        isRequesting = true
        
        Task {
            let granted = await permissionManager.requestAllPermissions()
            
            await MainActor.run {
                isRequesting = false
                
                if granted {
                    HapticManager.success()
                    appViewModel.navigateToMain()
                }
            }
        }
    }
}

struct PermissionStatusRow: View {
    let icon: String
    let title: String
    let status: AppPermissionStatus
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(AppColors.gradient)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            statusView
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    @ViewBuilder
    private var statusView: some View {
        switch status {
        case .authorized:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .denied, .restricted:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        case .notDetermined:
            Image(systemName: "questionmark.circle.fill")
                .foregroundColor(.orange)
        }
    }
}

#Preview {
    PermissionRequestView()
        .environmentObject(AppViewModel())
        .environmentObject(PermissionManager.shared)
}
