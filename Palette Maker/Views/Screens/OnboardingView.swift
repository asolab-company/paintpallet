import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RadialGradient(
                    colors: [Color(hex: "8C000D"), Color(hex: "160002")],
                    center: UnitPoint(x: 0.5013, y: 0.8862),
                    startRadius: 0,
                    endRadius: geometry.size.height * 0.8862
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: max(geometry.safeAreaInsets.top, 20) + 60)
                    
                    Text("Welcome to\nPalette Maker")
                        .font(.system(size: 36, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                        .frame(height: 48)
                    
                    Image("app-icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: min(geometry.size.width * 0.65, 280))
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Spacer()
                        .frame(height: 48)
                    
                    VStack(spacing: 12) {
                        Text("📷 Take or upload a photo.")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("🎨 Instantly get a palette of its most beautiful shades.")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("💾 Save your favorite color sets for design, art, or inspiration.")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                        .frame(height: 48)
                    
                    Button(action: {
                        HapticManager.lightImpact()
                        appViewModel.completeOnboarding()
                    }) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "5C3D00"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppColors.buttonGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 24)
                    
                    Spacer()
                        .frame(height: 20)
                    
                    TermsTextView()
                        .padding(.horizontal, 24)
                    
                    Spacer()
                        .frame(height: max(geometry.safeAreaInsets.bottom, 20) + 40)
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct TermsTextView: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("by proceeding you accept")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
            
            HStack(spacing: 4) {
                Text("our")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                
                Button(action: {
                    HapticManager.lightImpact()
                    openURL("https://docs.google.com/document/d/e/2PACX-1vQqGF8n2w2SA2HpEx8rgHgophNW05QLAnai_XxBLwoxRI4FYcPRFPhBk7GVspme_OOxD1Viw_8yGkoN/pub")
                }) {
                    Text("terms of use")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "D98600"))
                }
                
                Text("and")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                
                Button(action: {
                    HapticManager.lightImpact()
                    openURL("https://docs.google.com/document/d/e/2PACX-1vQqGF8n2w2SA2HpEx8rgHgophNW05QLAnai_XxBLwoxRI4FYcPRFPhBk7GVspme_OOxD1Viw_8yGkoN/pub")
                }) {
                    Text("privacy policy")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "D98600"))
                }
            }
        }
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppViewModel())
}
