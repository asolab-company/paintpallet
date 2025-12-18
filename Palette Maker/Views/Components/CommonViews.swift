import SwiftUI

struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.8))
            )
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

struct LoadingView: View {
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(AppColors.primaryRed)
            
            if let message = message {
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "paintpalette")
                .font(.system(size: 60))
                .foregroundStyle(AppColors.gradient)
            
            VStack(spacing: 8) {
                Text("No Palettes Yet")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Take or choose a photo to extract\nbeautiful color palettes")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
}

struct PermissionPopupView: View {
    let title: String
    let message: String
    let onAllow: () -> Void
    let onDeny: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(AppColors.gradient)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "camera.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            
            // Text
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Buttons
            VStack(spacing: 12) {
                GradientButton(title: "Allow Access") {
                    onAllow()
                }
                
                Button("Not Now") {
                    HapticManager.lightImpact()
                    onDeny()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
        )
        .padding(.horizontal, 40)
        .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: 15)
    }
}

struct SettingsRowView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.lightImpact()
            action()
        }) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    VStack(spacing: 30) {
        ToastView(message: "Color copied to clipboard!")
        
        LoadingView(message: "Extracting colors...")
        
        EmptyStateView()
        
        SettingsRowView(
            icon: "square.and.arrow.up",
            iconColor: AppColors.primaryRed,
            title: "Share App"
        ) {}
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
