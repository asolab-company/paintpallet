import SwiftUI

struct GradientButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticManager.lightImpact()
            action()
        }) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(Color(hex: "5C3D00"))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppColors.buttonGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(title)
    }
}

struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticManager.lightImpact()
            action()
        }) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(AppColors.primaryRed)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppColors.gradient, lineWidth: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(title)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct CopyButton: View {
    let onCopy: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.lightImpact()
            onCopy()
        }) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 32, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.2))
                )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Copy color")
    }
}

struct LinkButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.lightImpact()
            action()
        }) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.primaryOrange)
                .underline()
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        GradientButton(title: "Continue", icon: "arrow.right") {}
        SecondaryButton(title: "Take Photo", icon: "camera") {}
        CopyButton {}
        LinkButton(title: "Privacy Policy") {}
    }
    .padding()
}
