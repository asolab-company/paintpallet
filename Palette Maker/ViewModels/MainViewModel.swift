import Combine
import SwiftUI

@MainActor
final class MainViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var showDeleteConfirmation: Bool = false
    @Published var paletteToDelete: Palette?
    
    private let persistenceManager: PersistenceManager
    private let permissionManager: PermissionManager
    private var cancellables = Set<AnyCancellable>()
    
    @Published private(set) var palettes: [Palette] = []
    
    var hasPalettes: Bool {
        !palettes.isEmpty
    }
    
    var hasCameraPermission: Bool {
        permissionManager.hasCameraPermission
    }
    
    var hasPhotoLibraryPermission: Bool {
        permissionManager.hasPhotoLibraryPermission
    }
    
    init(
        persistenceManager: PersistenceManager = .shared,
        permissionManager: PermissionManager = .shared
    ) {
        self.persistenceManager = persistenceManager
        self.permissionManager = permissionManager
        
        self.palettes = persistenceManager.palettes
        
        persistenceManager.$palettes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newPalettes in
                self?.palettes = newPalettes
            }
            .store(in: &cancellables)
    }
    
    func refreshPalettes() {
        persistenceManager.loadPalettes()
    }
    
    func deletePalettes(at offsets: IndexSet) {
        persistenceManager.deletePalettes(at: offsets)
    }
    
    func deletePalette(id: UUID) {
        persistenceManager.deletePalette(id: id)
    }
    
    func copyColor(_ hex: String) -> Bool {
        UIPasteboard.general.string = hex
        HapticManager.success()
        return true
    }
    
    func checkPermissions() {
        permissionManager.checkCurrentPermissions()
    }
}
