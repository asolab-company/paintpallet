import XCTest
@testable import Palette_Maker

@MainActor
final class PersistenceManagerTests: XCTestCase {
    
    var persistenceManager: PersistenceManager!
    
    override func setUp() async throws {
        try await super.setUp()
        persistenceManager = PersistenceManager.shared
        // Clear existing palettes for testing
        persistenceManager.clearAllPalettes()
    }
    
    override func tearDown() async throws {
        persistenceManager.clearAllPalettes()
        persistenceManager = nil
        try await super.tearDown()
    }
    
    func testSavePalette() {
        let colors = ["#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF", "#00FFFF"]
        
        persistenceManager.savePalette(colors: colors)
        
        XCTAssertEqual(persistenceManager.palettes.count, 1)
        XCTAssertEqual(persistenceManager.palettes.first?.colors, colors)
    }
    
    func testSaveMultiplePalettes() {
        let colors1 = ["#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF", "#00FFFF"]
        let colors2 = ["#111111", "#222222", "#333333", "#444444", "#555555", "#666666"]
        
        persistenceManager.savePalette(colors: colors1)
        persistenceManager.savePalette(colors: colors2)
        
        XCTAssertEqual(persistenceManager.palettes.count, 2)
    }
    
    func testNewPalettesAreAddedAtBeginning() {
        let colors1 = ["#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF", "#00FFFF"]
        let colors2 = ["#111111", "#222222", "#333333", "#444444", "#555555", "#666666"]
        
        persistenceManager.savePalette(colors: colors1)
        persistenceManager.savePalette(colors: colors2)
        
        XCTAssertEqual(persistenceManager.palettes.first?.colors, colors2)
    }
    
    func testDeletePaletteById() {
        let colors = ["#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF", "#00FFFF"]
        persistenceManager.savePalette(colors: colors)
        let paletteId = persistenceManager.palettes.first!.id
        
        persistenceManager.deletePalette(id: paletteId)
        
        XCTAssertEqual(persistenceManager.palettes.count, 0)
    }
    
    func testDeletePalettesAtOffsets() {
        for i in 0..<5 {
            persistenceManager.savePalette(colors: ["#\(i)00000", "#00\(i)000", "#0000\(i)0", "#000000", "#000000", "#000000"])
        }
        
        persistenceManager.deletePalettes(at: IndexSet(integer: 0))
        
        XCTAssertEqual(persistenceManager.palettes.count, 4)
    }
    
    func testClearAllPalettes() {
        for i in 0..<5 {
            persistenceManager.savePalette(colors: ["#\(i)00000", "#00\(i)000", "#0000\(i)0", "#000000", "#000000", "#000000"])
        }
        
        persistenceManager.clearAllPalettes()
        
        XCTAssertEqual(persistenceManager.palettes.count, 0)
    }
    
    func testMaxPalettesLimit() {
        for i in 0..<105 {
            let hexSuffix = String(format: "%06X", i)
            persistenceManager.savePalette(colors: ["#\(hexSuffix)", "#000000", "#000000", "#000000", "#000000", "#000000"])
        }
        
        XCTAssertLessThanOrEqual(persistenceManager.palettes.count, 100)
    }
    
    func testOnboardingFlag() {
        UserDefaults.standard.removeObject(forKey: "has_seen_onboarding")
        
        persistenceManager.completeOnboarding()
        
        XCTAssertTrue(persistenceManager.hasSeenOnboarding)
    }
}
