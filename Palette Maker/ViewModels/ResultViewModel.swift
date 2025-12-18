import Combine
import SwiftUI
import UIKit

@MainActor
final class ResultViewModel: ObservableObject {
    @Published var extractedColors: [String] = []
    @Published var isExtracting: Bool = false
    @Published var errorMessage: String?
    
    let image: UIImage
    
    private let colorExtractionService: ColorExtractionService
    private let persistenceManager: PersistenceManager
    
    init(
        image: UIImage,
        colorExtractionService: ColorExtractionService = .shared,
        persistenceManager: PersistenceManager = .shared
    ) {
        self.image = image
        self.colorExtractionService = colorExtractionService
        self.persistenceManager = persistenceManager
        print("[ResultViewModel] Initialized with image size: \(image.size)")
    }
    
    func extractColors() async {
        guard !isExtracting && extractedColors.isEmpty else {
            print("[ResultViewModel] Skipping extraction - already extracting or colors exist")
            return
        }
        
        print("[ResultViewModel] Starting color extraction")
        isExtracting = true
        errorMessage = nil
        
        let colors = await colorExtractionService.extractColors(from: image)
        
        print("[ResultViewModel] Extraction complete, got \(colors.count) colors: \(colors)")
        
        await MainActor.run {
            extractedColors = colors
            isExtracting = false
        }
    }
    
    func savePalette() {
        guard !extractedColors.isEmpty else { return }
        
        let thumbnail = createThumbnail(from: image)
        
        persistenceManager.savePalette(
            colors: extractedColors,
            thumbnail: thumbnail
        )
        
        HapticManager.success()
    }
    
    private func createThumbnail(from image: UIImage) -> UIImage? {
        let maxSize: CGFloat = 100
        let scale = min(maxSize / image.size.width, maxSize / image.size.height, 1.0)
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return thumbnail
    }
    
    func copyColor(_ hex: String) -> Bool {
        UIPasteboard.general.string = hex
        HapticManager.success()
        return true
    }
}
