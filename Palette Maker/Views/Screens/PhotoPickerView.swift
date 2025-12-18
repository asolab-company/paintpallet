import SwiftUI
import PhotosUI

struct PhotoPickerView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedItem: PhotosPickerItem?
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                // This is hidden as we auto-present
                Color.clear
            }
            .photosPickerStyle(.inline)
            .photosPickerDisabledCapabilities([.collectionNavigation, .stagingArea])
            .ignoresSafeArea()
            
            // Custom header overlay
            VStack {
                pickerHeader
                Spacer()
            }
            
            // Loading overlay
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                LoadingView(message: "Loading image...")
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let item = newItem else { return }
            loadImage(from: item)
        }
    }
    
    private var pickerHeader: some View {
        HStack {
            Button(action: {
                HapticManager.lightImpact()
                appViewModel.navigateBack()
            }) {
                Text("Cancel")
                    .font(.system(size: 17))
                    .foregroundColor(AppColors.primaryRed)
            }
            
            Spacer()
            
            Text("Select Photo")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Invisible spacer for centering
            Text("Cancel")
                .font(.system(size: 17))
                .opacity(0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color(.systemBackground)
                .opacity(0.95)
        )
    }
    
    private func loadImage(from item: PhotosPickerItem) {
        isLoading = true
        
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        isLoading = false
                        appViewModel.navigateToResult(image: image)
                    }
                } else {
                    await MainActor.run {
                        isLoading = false
                        HapticManager.error()
                    }
                }
            } catch {
                print("Error loading image: \(error)")
                await MainActor.run {
                    isLoading = false
                    HapticManager.error()
                }
            }
        }
    }
}

struct PhotoPickerModal: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var showPicker = true
    @State private var selectedItem: PhotosPickerItem?
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Button(action: {
                        HapticManager.lightImpact()
                        appViewModel.navigateBack()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    Text("Choose Photo")
                        .font(.system(size: 17, weight: .semibold))
                    
                    Spacer()
                    
                    // Spacer for centering
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 8)
                
                Spacer()
                
                // Icon and instructions
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(AppColors.gradient)
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Text("Select a photo from your library\nto extract its color palette")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Photo picker button
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 12) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text("Open Photo Library")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppColors.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            
            // Loading overlay
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                LoadingView(message: "Loading image...")
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let item = newItem else { return }
            loadImage(from: item)
        }
    }
    
    private func loadImage(from item: PhotosPickerItem) {
        isLoading = true
        
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        isLoading = false
                        appViewModel.navigateToResult(image: image)
                    }
                } else {
                    await MainActor.run {
                        isLoading = false
                        HapticManager.error()
                    }
                }
            } catch {
                print("Error loading image: \(error)")
                await MainActor.run {
                    isLoading = false
                    HapticManager.error()
                }
            }
        }
    }
}

#Preview {
    PhotoPickerModal()
        .environmentObject(AppViewModel())
}
