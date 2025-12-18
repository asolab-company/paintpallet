import SwiftUI

struct ResultScreenView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel: ResultViewModel
    
    init(image: UIImage) {
        _viewModel = StateObject(wrappedValue: ResultViewModel(image: image))
    }
    
    var body: some View {
        ZStack {
            // Full-screen image background
            Image(uiImage: viewModel.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .ignoresSafeArea()
            
            // Gradient overlay for readability at bottom
            VStack {
                Spacer()
                LinearGradient(
                    colors: [
                        Color.black.opacity(0),
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.7),
                        Color.black.opacity(0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 350)
            }
            .ignoresSafeArea()
            
            // Content overlay
            VStack(spacing: 0) {
                Spacer()
                
                // Palette section at bottom
                paletteSection
                
                // Action buttons
                actionButtons
            }
            
            // Toast
            if appViewModel.showingToast {
                VStack {
                    Spacer()
                    ToastView(message: appViewModel.toastMessage)
                        .padding(.bottom, 180)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.3), value: appViewModel.showingToast)
            }
        }
        .task {
            await viewModel.extractColors()
        }
    }
    
    // MARK: - Palette Section
    
    private var paletteSection: some View {
        VStack(spacing: 16) {
            if !viewModel.extractedColors.isEmpty {
                ColorPaletteView(colors: viewModel.extractedColors) { hexColor in
                    if viewModel.copyColor(hexColor) {
                        appViewModel.showToast(message: "Copied \(hexColor)")
                    }
                }
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            // New Palette button with blur background
            Button(action: {
                HapticManager.lightImpact()
                appViewModel.openNewPalette()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                    Text("New Palette")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color(hex: "5C3D00"))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AppColors.buttonGradient)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Save Palette button
            GradientButton(title: "Save Palette", icon: "square.and.arrow.down") {
                viewModel.savePalette()
                appViewModel.navigateToMain()
            }
            .disabled(viewModel.extractedColors.isEmpty)
            .opacity(viewModel.extractedColors.isEmpty ? 0.6 : 1.0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .padding(.bottom, 20) // Extra padding for safe area
    }
}

#Preview {
    ResultScreenView(image: UIImage(systemName: "photo.fill")!)
        .environmentObject(AppViewModel())
}
