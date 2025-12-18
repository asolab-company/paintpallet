import PhotosUI
import SwiftUI

private struct DesignColors {
    static let heroGradient = LinearGradient(
        colors: [Color(hex: "870207"), Color(hex: "D98600")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let buttonGradient = LinearGradient(
        colors: [Color(hex: "FFE031"), Color(hex: "FE9B5D")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static func paletteBackgroundGradient(size: CGSize) -> RadialGradient {
        RadialGradient(
            colors: [Color(hex: "8C000D"), Color(hex: "160002")],
            center: UnitPoint(x: 0.5013, y: 0.8862),
            startRadius: 0,
            endRadius: size.height * 0.8862
        )
    }
}

struct MainScreenView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var permissionManager: PermissionManager
    @StateObject private var viewModel = MainViewModel()
    
    @State private var showPermissionPopup = false
    @State private var pendingAction: ImageSourceType?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isLoadingPhoto = false
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let safeAreaTop = geometry.safeAreaInsets.top
            
            let heroHeight = screenHeight * 0.58
            let scrollHeight = screenHeight * 0.42
            
            ZStack {
                VStack(spacing: 0) {
                    DesignColors.heroGradient
                        .frame(height: heroHeight + safeAreaTop)
                    
                    DesignColors.paletteBackgroundGradient(size: CGSize(
                        width: screenWidth,
                        height: scrollHeight
                    ))
                }
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    heroSection(
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                        heroHeight: heroHeight,
                        safeAreaTop: safeAreaTop
                    )
                    .frame(height: heroHeight + safeAreaTop)
                    
                    paletteSection
                        .frame(height: scrollHeight)
                }
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            HapticManager.lightImpact()
                            appViewModel.navigateToSettings()
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: screenWidth * 0.055))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 44, height: 44)
                        }
                        .padding(.trailing, 16)
                        .padding(.top, safeAreaTop + 48)
                    }
                    Spacer()
                }
                
                overlays
            }
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            print("[MainScreenView] View appeared, resetting state")
            viewModel.refreshPalettes()
            viewModel.checkPermissions()
            selectedPhotoItem = nil
            isLoadingPhoto = false
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let item = newItem else {
                print("[MainScreenView] Photo picker dismissed without selection")
                return
            }
            print("[MainScreenView] Photo selected, starting load")
            loadSelectedPhoto(from: item)
        }
    }
    
    private func heroSection(screenWidth: CGFloat, screenHeight: CGFloat, heroHeight: CGFloat, safeAreaTop: CGFloat) -> some View {
        let horizontalPadding = screenWidth * 0.04
        let iconSize = screenWidth * 0.60 // 60% of screen width (large, prominent)
        let buttonWidth = screenWidth * 0.42
        let buttonHeight = screenHeight * 0.06
        let buttonGap = screenWidth * 0.04
        let buttonCornerRadius = screenWidth * 0.035
        let settingsIconSize = screenWidth * 0.055
        let fontSize = screenWidth * 0.042
        let buttonFontSize = screenWidth * 0.038
        let buttonIconSize = screenWidth * 0.04
        
        let verticalPadding = heroHeight * 0.06
        let iconToTextSpacing = heroHeight * 0.035
        let textToButtonSpacing = heroHeight * 0.045
        
        return VStack(spacing: 0) {
            Spacer()
                .frame(height: safeAreaTop + verticalPadding)
            
            Image("app-icon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
                .shadow(color: .black.opacity(0.3), radius: screenWidth * 0.05, x: 0, y: screenHeight * 0.012).padding(.top, 48)
            
            Spacer()
                .frame(height: iconToTextSpacing)
            
            Text("Create beautiful color palettes\nfrom your photos in seconds.")
                .font(.system(size: fontSize, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(screenHeight * 0.005)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, horizontalPadding)
            
            Spacer()
                .frame(height: textToButtonSpacing)
            
            HStack(spacing: buttonGap) {
                Button(action: {
                    HapticManager.lightImpact()
                    handleTakePhoto()
                }) {
                    HStack(spacing: screenWidth * 0.02) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: buttonIconSize, weight: .semibold))
                        Text("Take Photo")
                            .font(.system(size: buttonFontSize, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "5C3D00"))
                    .frame(width: buttonWidth, height: buttonHeight)
                    .background(DesignColors.buttonGradient)
                    .clipShape(RoundedRectangle(cornerRadius: buttonCornerRadius))
                }
                .buttonStyle(ScaleButtonStyle())
                
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: screenWidth * 0.02) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: buttonIconSize, weight: .semibold))
                        Text("Choose Photo")
                            .font(.system(size: buttonFontSize, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "5C3D00"))
                    .frame(width: buttonWidth, height: buttonHeight)
                    .background(DesignColors.buttonGradient)
                    .clipShape(RoundedRectangle(cornerRadius: buttonCornerRadius))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            Spacer()
                .frame(height: verticalPadding)
        }
    }
    
    private var paletteSection: some View {
        Group {
            if viewModel.hasPalettes {
                palettesList
            } else {
                emptyStateView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "paintpalette")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Palettes Yet")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Take or choose a photo to extract\nbeautiful color palettes")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
    
    private var palettesList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.palettes) { palette in
                    SwipeableDeleteCard(
                        paletteId: palette.id,
                        onDelete: {
                            viewModel.deletePalette(id: palette.id)
                        }
                    ) {
                        PaletteCardView(palette: palette) { hexColor in
                            if viewModel.copyColor(hexColor) {
                                appViewModel.showToast(message: "Copied \(hexColor)")
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
            .padding(.vertical, 16)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.palettes.count)
        }
    }
    
    private var overlays: some View {
        ZStack {
            if appViewModel.showingToast {
                VStack {
                    Spacer()
                    ToastView(message: appViewModel.toastMessage)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.3), value: appViewModel.showingToast)
            }
            
            if showPermissionPopup {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showPermissionPopup = false
                        }
                    }
                
                PermissionPopupView(
                    title: permissionPopupTitle,
                    message: permissionPopupMessage,
                    onAllow: {
                        requestPermission()
                    },
                    onDeny: {
                        withAnimation {
                            showPermissionPopup = false
                        }
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
            

        }
    }
    
    private func loadSelectedPhoto(from item: PhotosPickerItem) {
        guard !isLoadingPhoto else {
            print("[MainScreenView] Already loading photo, ignoring duplicate request")
            return
        }
        
        isLoadingPhoto = true
        appViewModel.lastImageSource = .photoLibrary
        print("[MainScreenView] Starting photo load from picker")
        
        Task {
            defer {
                Task { @MainActor in
                    isLoadingPhoto = false
                    selectedPhotoItem = nil
                }
            }
            
            do {
                print("[MainScreenView] Loading transferable data...")
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    print("[MainScreenView] ERROR: Failed to load data from photo picker item")
                    await MainActor.run { HapticManager.error() }
                    return
                }
                
                print("[MainScreenView] Data loaded, size: \(data.count) bytes")
                guard let image = UIImage(data: data) else {
                    print("[MainScreenView] ERROR: Failed to create UIImage from data")
                    await MainActor.run { HapticManager.error() }
                    return
                }
                
                print("[MainScreenView] Image created successfully, size: \(image.size)")
                
                try? await Task.sleep(nanoseconds: 150_000_000)
                
                await MainActor.run {
                    print("[MainScreenView] Navigating to result screen")
                    appViewModel.navigateToResult(image: image)
                }
            } catch {
                print("[MainScreenView] ERROR loading image: \(error)")
                await MainActor.run { HapticManager.error() }
            }
        }
    }
    
    private var permissionPopupTitle: String {
        switch pendingAction {
        case .camera:
            return "Camera Access"
        case .photoLibrary:
            return "Photo Library Access"
        case .none:
            return "Permission Required"
        }
    }
    
    private var permissionPopupMessage: String {
        switch pendingAction {
        case .camera:
            return "We need access to your camera to capture photos for color extraction."
        case .photoLibrary:
            return "We need access to your photo library to select images for color extraction."
        case .none:
            return "Permission is required to continue."
        }
    }
    
    private func handleTakePhoto() {
        if permissionManager.hasCameraPermission {
            appViewModel.navigateToCamera()
        } else if permissionManager.cameraStatus == .notDetermined {
            pendingAction = .camera
            withAnimation {
                showPermissionPopup = true
            }
        } else {
            permissionManager.openAppSettings()
        }
    }
    
    private func requestPermission() {
        Task {
            var granted = false
            
            switch pendingAction {
            case .camera:
                granted = await permissionManager.requestCameraPermission()
            case .photoLibrary:
                granted = await permissionManager.requestPhotoLibraryPermission()
            case .none:
                break
            }
            
            await MainActor.run {
                withAnimation {
                    showPermissionPopup = false
                }
                
                if granted {
                    HapticManager.success()
                    switch pendingAction {
                    case .camera:
                        appViewModel.navigateToCamera()
                    case .photoLibrary:
                        break
                    case .none:
                        break
                    }
                }
                
                pendingAction = nil
            }
        }
    }
}

struct SwipeableDeleteCard<Content: View>: View {
    let paletteId: UUID
    let onDelete: () -> Void
    let content: Content
    
    @GestureState private var isDragging: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var cardState: CardState = .idle
    @State private var hasStartedDrag: Bool = false
    
    private let cardHeight: CGFloat = 220
    private let cornerRadius: CGFloat = 16
    private let deleteThreshold: CGFloat = 180
    private let minimumDragDistance: CGFloat = 25
    
    private var rightCornerRadius: CGFloat {
        let swipeProgress = min(1.0, abs(dragOffset) / deleteThreshold)
        return cornerRadius * (1.0 - swipeProgress)
    }
    
    private enum CardState: Equatable {
        case idle
        case dragging
        case deleting
    }
    
    init(paletteId: UUID, onDelete: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.paletteId = paletteId
        self.onDelete = onDelete
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            deleteBackground
            
            cardContent
        }
        .frame(height: cardHeight)
        .clipped()
        .onAppear {
            resetState()
        }
        .id(paletteId)
    }
    
    private func resetState() {
        dragOffset = 0
        cardState = .idle
        hasStartedDrag = false
    }
    
    private var deleteBackground: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                
                ZStack {
                    Rectangle()
                        .fill(Color.red)
                    
                    VStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Delete")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: visibleDeleteWidth(in: geometry))
            }
            .frame(height: cardHeight)
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: cornerRadius,
                topTrailingRadius: cornerRadius
            )
        )
        .opacity(dragOffset < 0 ? 1 : 0)
    }
    
    private var cardContent: some View {
        content
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: cornerRadius,
                    bottomLeadingRadius: cornerRadius,
                    bottomTrailingRadius: rightCornerRadius,
                    topTrailingRadius: rightCornerRadius
                )
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .offset(x: dragOffset)
            .contentShape(Rectangle())
            .gesture(swipeGesture)
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        if cardState != .deleting && cardState != .idle {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                resetState()
                            }
                        }
                    }
            )
    }
    
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .updating($isDragging) { _, state, _ in
                state = true
            }
            .onChanged { value in
                guard cardState != .deleting else { return }
                
                let translation = value.translation.width
                
                if abs(translation) > 5 {
                    hasStartedDrag = true
                }
                
                if translation < 0 {
                    let resistedTranslation = applyResistance(translation)
                    dragOffset = resistedTranslation
                } else if dragOffset < 0 {
                    dragOffset = min(0, dragOffset + translation)
                }
                
                cardState = .dragging
            }
            .onEnded { value in
                guard cardState != .deleting else { return }
                
                let velocity = value.predictedEndTranslation.width
                let actualDragDistance = abs(value.translation.width)
                
                let passedThreshold = actualDragDistance > deleteThreshold
                let hasHighVelocity = velocity < -800 && actualDragDistance > minimumDragDistance
                
                if hasStartedDrag && (passedThreshold || hasHighVelocity) {
                    performDeletion()
                } else {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        resetState()
                    }
                }
                
                hasStartedDrag = false
            }
    }
    
    private func applyResistance(_ translation: CGFloat) -> CGFloat {
        let resistance: CGFloat = 0.85
        return translation * resistance
    }
    
    private func visibleDeleteWidth(in geometry: GeometryProxy) -> CGFloat {
        let width = -dragOffset
        return max(0, min(width, geometry.size.width))
    }
    
    private func performDeletion() {
        guard cardState != .deleting else { return }
        
        cardState = .deleting
        hasStartedDrag = false
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            dragOffset = -UIScreen.main.bounds.width - 50
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            HapticManager.success()
            
            self.onDelete()
        }
    }
}

#Preview {
    MainScreenView()
        .environmentObject(AppViewModel())
        .environmentObject(PermissionManager.shared)
}
