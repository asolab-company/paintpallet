import Foundation
import SwiftUI

struct Palette: Identifiable, Codable, Equatable {
    let id: UUID
    let colors: [String]
    let createdAt: Date
    let thumbnailData: Data?
    
    init(id: UUID = UUID(), colors: [String], createdAt: Date = Date(), thumbnailData: Data? = nil) {
        self.id = id
        self.colors = colors
        self.createdAt = createdAt
        self.thumbnailData = thumbnailData
    }
    
    static func color(from hex: String) -> Color {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        
        let r, g, b: UInt64
        switch cleanHex.count {
        case 3:
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (128, 128, 128)
        }
        
        return Color(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}

enum AppColors {
    static let primaryRed = Color(hex: "870207")
    static let primaryOrange = Color(hex: "D98600")
    
    static var gradient: LinearGradient {
        LinearGradient(
            colors: [primaryRed, primaryOrange],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    static var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FFE031"), Color(hex: "FE9B5D")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    static func radialBackground(geometry: GeometryProxy) -> RadialGradient {
        RadialGradient(
            colors: [Color(hex: "8C000D"), Color(hex: "160002")],
            center: UnitPoint(x: 0.5013, y: 0.8862),
            startRadius: 0,
            endRadius: geometry.size.height * 0.8862
        )
    }
    
    static var verticalGradient: LinearGradient {
        LinearGradient(
            colors: [primaryRed, primaryOrange],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

extension Color {
    init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        
        let r, g, b: UInt64
        switch cleanHex.count {
        case 3:
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (128, 128, 128)
        }
        
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
    
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else { 
            return "000000" 
        }
        
        let r: CGFloat = components[0]
        let g: CGFloat = components[1]
        let b: CGFloat = components[2]
        
        return String(
            format: "#%02X%02X%02X",
            Int(r * 255),
            Int(g * 255),
            Int(b * 255)
        )
    }
}

enum ImageSourceType {
    case camera
    case photoLibrary
}

enum AppPermissionStatus {
    case notDetermined
    case authorized
    case denied
    case restricted
    
    var isGranted: Bool {
        self == .authorized
    }
}

enum AppScreen: Equatable {
    case splash
    case onboarding
    case permissionRequest
    case main
    case camera
    case photoPicker
    case result(image: UIImage)
    case settings
    
    static func == (lhs: AppScreen, rhs: AppScreen) -> Bool {
        switch (lhs, rhs) {
        case (.splash, .splash),
             (.onboarding, .onboarding),
             (.permissionRequest, .permissionRequest),
             (.main, .main),
             (.camera, .camera),
             (.photoPicker, .photoPicker),
             (.settings, .settings):
            return true
        case (.result, .result):
            return true
        default:
            return false
        }
    }
}
