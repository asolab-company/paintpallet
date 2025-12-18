import Combine
import Foundation
import SwiftUI
import UIKit

@MainActor
final class PersistenceManager: ObservableObject {
    static let shared = PersistenceManager()
    
    private let palettesKey = "saved_palettes"
    private let hasSeenOnboardingKey = "has_seen_onboarding"
    private let maxPalettes = 100
    
    @Published private(set) var palettes: [Palette] = []
    
    private init() {
        loadPalettes()
    }
    
    var hasSeenOnboarding: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasSeenOnboardingKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasSeenOnboardingKey)
        }
    }
    
    func completeOnboarding() {
        hasSeenOnboarding = true
    }
    
    func loadPalettes() {
        guard let data = UserDefaults.standard.data(forKey: palettesKey) else {
            palettes = []
            return
        }
        
        do {
            let decoder = JSONDecoder()
            palettes = try decoder.decode([Palette].self, from: data)
            palettes.sort { $0.createdAt > $1.createdAt }
        } catch {
            print("Error loading palettes: \(error)")
            palettes = []
        }
    }
    
    func savePalette(colors: [String], thumbnail: UIImage? = nil) {
        var thumbnailData: Data?
        if let thumbnail = thumbnail {
            thumbnailData = thumbnail.jpegData(compressionQuality: 0.3)
        }
        
        let palette = Palette(
            colors: colors,
            thumbnailData: thumbnailData
        )
        
        palettes.insert(palette, at: 0)
        
        if palettes.count > maxPalettes {
            palettes = Array(palettes.prefix(maxPalettes))
        }
        
        persistPalettes()
    }
    
    func deletePalette(id: UUID) {
        palettes.removeAll { $0.id == id }
        persistPalettes()
    }
    
    func deletePalettes(at offsets: IndexSet) {
        palettes.remove(atOffsets: offsets)
        persistPalettes()
    }
    
    func clearAllPalettes() {
        palettes = []
        persistPalettes()
    }
    
    private func persistPalettes() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(palettes)
            UserDefaults.standard.set(data, forKey: palettesKey)
            UserDefaults.standard.synchronize()
        } catch {
            print("Error saving palettes: \(error)")
        }
    }
}
