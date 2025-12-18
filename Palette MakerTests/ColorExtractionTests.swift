import XCTest
@testable import Palette_Maker

final class ColorExtractionTests: XCTestCase {
    
    var colorExtractionService: ColorExtractionService!
    
    override func setUp() {
        super.setUp()
        colorExtractionService = ColorExtractionService.shared
    }
    
    override func tearDown() {
        colorExtractionService = nil
        super.tearDown()
    }
    
    func testExtractColorsReturnsExactlySixColors() async {
        let image = createTestImage(color: .red)
        
        let colors = await colorExtractionService.extractColors(from: image)
        
        XCTAssertEqual(colors.count, 6, "Should always return exactly 6 colors")
    }
    
    func testExtractedColorsAreValidHexFormat() async {
        let image = createTestImage(color: .blue)
        
        let colors = await colorExtractionService.extractColors(from: image)
        
        for hex in colors {
            XCTAssertTrue(hex.hasPrefix("#"), "Hex color should start with #")
            XCTAssertEqual(hex.count, 7, "Hex color should be 7 characters (#RRGGBB)")
            
            let hexChars = hex.dropFirst()
            XCTAssertTrue(hexChars.allSatisfy { $0.isHexDigit }, "Should only contain hex characters")
        }
    }
    
    func testExtractColorsFromSolidColorImage() async {
        let redImage = createTestImage(color: .red, size: CGSize(width: 100, height: 100))
        
        let colors = await colorExtractionService.extractColors(from: redImage)
        
        XCTAssertFalse(colors.isEmpty, "Should extract colors from solid image")
        XCTAssertEqual(colors.count, 6, "Should return exactly 6 colors")
    }
    
    func testExtractColorsFromGradientImage() async {
        let gradientImage = createGradientTestImage()
        
        let colors = await colorExtractionService.extractColors(from: gradientImage)
        
        XCTAssertEqual(colors.count, 6, "Should return exactly 6 colors")
        
        let uniqueColors = Set(colors)
        XCTAssertGreaterThan(uniqueColors.count, 1, "Should extract diverse colors from gradient")
    }
    
    func testPaletteColorFromHex() {
        let testCases: [(hex: String, expectedComponents: (r: Double, g: Double, b: Double))] = [
            ("#FF0000", (1.0, 0.0, 0.0)),  // Red
            ("#00FF00", (0.0, 1.0, 0.0)),  // Green
            ("#0000FF", (0.0, 0.0, 1.0)),  // Blue
            ("FFFFFF", (1.0, 1.0, 1.0)),   // White (no #)
            ("000000", (0.0, 0.0, 0.0)),
        ]
        
        for testCase in testCases {
            let color = Palette.color(from: testCase.hex)
            
            XCTAssertNotNil(color, "Should create color from hex: \(testCase.hex)")
        }
    }
    
    func testPaletteInitialization() {
        let colors = ["#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF", "#00FFFF"]
        
        let palette = Palette(colors: colors)
        
        XCTAssertEqual(palette.colors.count, 6)
        XCTAssertNotNil(palette.id)
        XCTAssertNotNil(palette.createdAt)
        XCTAssertNil(palette.thumbnailData)
    }
    
    func testPaletteCodable() throws {
        let colors = ["#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF", "#00FFFF"]
        let palette = Palette(colors: colors)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(palette)
        
        let decoder = JSONDecoder()
        let decodedPalette = try decoder.decode(Palette.self, from: data)
        
        XCTAssertEqual(decodedPalette.id, palette.id)
        XCTAssertEqual(decodedPalette.colors, palette.colors)
    }
    
    func testColorToHex() {
        let originalHex = "#FF5733"
        let color = Color(hex: originalHex)
        
        let resultHex = color.toHex()
        
        XCTAssertTrue(resultHex.hasPrefix("#"), "Result should start with #")
        XCTAssertEqual(resultHex.count, 7, "Result should be 7 characters")
    }
    
    func testColorHexWithThreeCharacters() {
        let hex = "F00"
        
        let color = Color(hex: hex)
        
        XCTAssertNotNil(color)
    }
    
    private func createTestImage(color: UIColor, size: CGSize = CGSize(width: 50, height: 50)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    private func createGradientTestImage(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        let context = UIGraphicsGetCurrentContext()!
        
        let colors = [UIColor.red.cgColor, UIColor.blue.cgColor]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil)!
        
        context.drawLinearGradient(
            gradient,
            start: .zero,
            end: CGPoint(x: size.width, y: size.height),
            options: []
        )
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}
