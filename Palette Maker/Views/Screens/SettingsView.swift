import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppColors.radialBackground(geometry: geometry)
                    .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                // Settings list
                ScrollView {
                    VStack(spacing: 12) {
                        SettingsRowView(
                            icon: "square.and.arrow.up",
                            iconColor: AppColors.primaryRed,
                            title: "Share App"
                        ) {
                            shareApp()
                        }
                        
                        SettingsRowView(
                            icon: "doc.text",
                            iconColor: AppColors.primaryOrange,
                            title: "Terms of Service"
                        ) {
                            openURL("https://docs.google.com/document/d/e/2PACX-1vQqGF8n2w2SA2HpEx8rgHgophNW05QLAnai_XxBLwoxRI4FYcPRFPhBk7GVspme_OOxD1Viw_8yGkoN/pub")
                        }
                        
                        SettingsRowView(
                            icon: "hand.raised",
                            iconColor: .blue,
                            title: "Privacy Policy"
                        ) {
                            openURL("https://docs.google.com/document/d/e/2PACX-1vQqGF8n2w2SA2HpEx8rgHgophNW05QLAnai_XxBLwoxRI4FYcPRFPhBk7GVspme_OOxD1Viw_8yGkoN/pub")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // App version
                    appVersion
                        .padding(.top, 40)
                }
            }
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Button(action: {
                HapticManager.lightImpact()
                appViewModel.navigateBack()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Back")
                        .font(.system(size: 17))
                }
                .foregroundColor(Color(hex: "FFE031"))
            }
            
            Spacer()
            
            Text("Settings")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Invisible spacer for centering
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                Text("Back")
                    .font(.system(size: 17))
            }
            .opacity(0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - App Version
    
    private var appVersion: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(AppColors.gradient.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(AppColors.gradient)
            }
            
            Text("Palette Maker")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Version 1.0.0")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Actions
    
    private func shareApp() {
        let appURL = "https://apps.apple.com/app/id6756739953"
        let message = "Check out Palette Maker - Extract beautiful color palettes from photos!"
        
        let activityItems: [Any] = [message, URL(string: appURL)!]
        
        let activityVC = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        // Get the window scene for presenting
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            return
        }
        
        // For iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootVC.view
            popover.sourceRect = CGRect(
                x: UIScreen.main.bounds.width / 2,
                y: UIScreen.main.bounds.height / 2,
                width: 0,
                height: 0
            )
        }
        
        rootVC.present(activityVC, animated: true)
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppViewModel())
}
