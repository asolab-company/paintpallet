import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

final class ColorExtractionService {
    static let shared = ColorExtractionService()
    
    private let context: CIContext
    private let targetColorCount = 6
    
    private let minLuminance: Double = 15.0
    private let maxLuminance: Double = 240.0
    private let minSaturation: Double = 0.08
    
    private init() {
        context = CIContext(options: [.useSoftwareRenderer: false])
    }
    
    func extractColors(from image: UIImage) async -> [String] {
        print("[ColorExtractionService] Starting extraction for image size: \(image.size)")
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    print("[ColorExtractionService] ERROR: Self is nil, returning default colors")
                    continuation.resume(returning: self?.defaultColors() ?? [])
                    return
                }
                
                let colors = self.performColorExtraction(from: image)
                print("[ColorExtractionService] Extraction complete: \(colors)")
                continuation.resume(returning: colors)
            }
        }
    }
    
    private func performColorExtraction(from image: UIImage) -> [String] {
        guard let cgImage = image.cgImage else {
            print("[ColorExtractionService] ERROR: Failed to get CGImage")
            return defaultColors()
        }
        
        let resizedImage = resizeImage(cgImage, maxDimension: 100)
        
        guard let pixelData = getPreprocessedPixelData(from: resizedImage) else {
            print("[ColorExtractionService] ERROR: Failed to get pixel data")
            return defaultColors()
        }
        
        print("[ColorExtractionService] Processing \(pixelData.count) valid pixels after filtering")
        
        if pixelData.count < 10 {
            print("[ColorExtractionService] WARNING: Too few valid pixels")
            return defaultColors()
        }
        
        let initialClusters = 12
        let clusters = improvedKMeansClustering(pixelData: pixelData, k: initialClusters)
        
        let selectedColors = selectBestColors(from: clusters, pixelData: pixelData, targetCount: targetColorCount)
        
        let sortedColors = sortByVisualProminence(colors: selectedColors, pixelData: pixelData)
        
        let hexColors = sortedColors.map { rgbToHex($0) }
        
        return hexColors
    }
    
    private func resizeImage(_ cgImage: CGImage, maxDimension: CGFloat) -> CGImage {
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        
        let scale = min(maxDimension / width, maxDimension / height, 1.0)
        let newWidth = Int(width * scale)
        let newHeight = Int(height * scale)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: 8,
            bytesPerRow: newWidth * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return cgImage
        }
        
        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        
        return context.makeImage() ?? cgImage
    }
    
    private func getPreprocessedPixelData(from cgImage: CGImage) -> [(r: Int, g: Int, b: Int)]? {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var colors: [(r: Int, g: Int, b: Int)] = []
        var colorCounts: [String: Int] = [:]
        
        for i in stride(from: 0, to: pixelData.count, by: bytesPerPixel) {
            let r = Int(pixelData[i])
            let g = Int(pixelData[i + 1])
            let b = Int(pixelData[i + 2])
            let a = Int(pixelData[i + 3])
            
            guard a > 128 else { continue }
            
            let color = (r: r, g: g, b: b)
            
            guard isValidColor(color) else { continue }
            
            let key = "\(r),\(g),\(b)"
            colorCounts[key, default: 0] += 1
            colors.append(color)
        }
        
        print("[ColorExtractionService] Filtered: \(colors.count) valid pixels from \(width * height) total")
        
        return colors.isEmpty ? nil : colors
    }
    
    private func isValidColor(_ color: (r: Int, g: Int, b: Int)) -> Bool {
        let hsl = rgbToHSL(color)
        
        if hsl.l < minLuminance {
            return hsl.s > 0.15
        }
        
        if hsl.l > maxLuminance {
            return false
        }
        
        if hsl.l > 30 && hsl.l < 210 {
            if hsl.s < minSaturation {
                return false
            }
        }
        
        return true
    }
    
    private func improvedKMeansClustering(pixelData: [(r: Int, g: Int, b: Int)], k: Int) -> [(r: Int, g: Int, b: Int)] {
        guard !pixelData.isEmpty else { return defaultRGBColors() }
        
        var centroids = initializeCentroids(from: pixelData, k: k)
        
        let maxIterations = 25
        var iteration = 0
        
        while iteration < maxIterations {
            var clusters: [[(r: Int, g: Int, b: Int)]] = Array(repeating: [], count: k)
            
            for pixel in pixelData {
                var minDistance = Double.infinity
                var closestIndex = 0
                
                for (index, centroid) in centroids.enumerated() {
                    let distance = perceptualColorDistance(pixel, centroid)
                    if distance < minDistance {
                        minDistance = distance
                        closestIndex = index
                    }
                }
                
                clusters[closestIndex].append(pixel)
            }
            
            var newCentroids: [(r: Int, g: Int, b: Int)] = []
            for (index, cluster) in clusters.enumerated() {
                if cluster.isEmpty {
                    newCentroids.append(centroids[index])
                } else {
                    var totalR = 0.0, totalG = 0.0, totalB = 0.0, totalWeight = 0.0
                    
                    for color in cluster {
                        let hsl = rgbToHSL(color)
                        let weight = 1.0 + hsl.s
                        totalR += Double(color.r) * weight
                        totalG += Double(color.g) * weight
                        totalB += Double(color.b) * weight
                        totalWeight += weight
                    }
                    
                    let avgR = Int(totalR / totalWeight)
                    let avgG = Int(totalG / totalWeight)
                    let avgB = Int(totalB / totalWeight)
                    newCentroids.append((r: avgR, g: avgG, b: avgB))
                }
            }
            
            let converged = zip(centroids, newCentroids).allSatisfy { old, new in
                perceptualColorDistance(old, new) < 3.0
            }
            
            centroids = newCentroids
            iteration += 1
            
            if converged {
                print("[ColorExtractionService] K-means converged at iteration \(iteration)")
                break
            }
        }
        
        return centroids
    }
    
    private func initializeCentroids(from pixelData: [(r: Int, g: Int, b: Int)], k: Int) -> [(r: Int, g: Int, b: Int)] {
        guard !pixelData.isEmpty else { return defaultRGBColors() }
        
        var centroids: [(r: Int, g: Int, b: Int)] = []
        
        let sortedBySaturation = pixelData.sorted { rgbToHSL($0).s > rgbToHSL($1).s }
        guard let firstCentroid = sortedBySaturation.first else {
            return Array(repeating: pixelData.randomElement()!, count: min(k, pixelData.count))
        }
        centroids.append(firstCentroid)
        
        while centroids.count < k {
            var distances: [Double] = []
            
            for pixel in pixelData {
                let minDist = centroids.map { perceptualColorDistance(pixel, $0) }.min() ?? 0
                distances.append(minDist * minDist)
            }
            
            let totalDistance = distances.reduce(0, +)
            guard totalDistance > 0 else {
                if let random = pixelData.randomElement() {
                    centroids.append(random)
                }
                continue
            }
            
            let threshold = Double.random(in: 0..<totalDistance)
            var cumulative = 0.0
            
            for (index, distance) in distances.enumerated() {
                cumulative += distance
                if cumulative >= threshold {
                    centroids.append(pixelData[index])
                    break
                }
            }
            
            if centroids.count < k && distances.count == pixelData.count {
                if let random = pixelData.randomElement() {
                    centroids.append(random)
                }
            }
        }
        
        return Array(centroids.prefix(k))
    }
    
    private func selectBestColors(from clusters: [(r: Int, g: Int, b: Int)], pixelData: [(r: Int, g: Int, b: Int)], targetCount: Int) -> [(r: Int, g: Int, b: Int)] {
        guard !clusters.isEmpty else { return defaultRGBColors() }
        
        var colorScores: [(color: (r: Int, g: Int, b: Int), score: Double)] = []
        
        for cluster in clusters {
            let frequency = pixelData.filter { perceptualColorDistance($0, cluster) < 30.0 }.count
            let frequencyScore = Double(frequency) / Double(pixelData.count)
            
            let hsl = rgbToHSL(cluster)
            let saturationScore = hsl.s
            
            let score = (frequencyScore * 0.6) + (saturationScore * 0.4)
            
            colorScores.append((color: cluster, score: score))
        }
        
        colorScores.sort { $0.score > $1.score }
        
        var selectedColors: [(r: Int, g: Int, b: Int)] = []
        let minDeltaE: Double = 20.0
        
        for candidate in colorScores {
            let isSufficientlyDifferent = selectedColors.allSatisfy { selected in
                perceptualColorDistance(candidate.color, selected) >= minDeltaE
            }
            
            if isSufficientlyDifferent {
                selectedColors.append(candidate.color)
            }
            
            if selectedColors.count >= targetCount {
                break
            }
        }
        
        if selectedColors.count < targetCount {
            for candidate in colorScores {
                if !selectedColors.contains(where: { $0 == candidate.color }) {
                    selectedColors.append(candidate.color)
                    if selectedColors.count >= targetCount {
                        break
                    }
                }
            }
        }
        
        while selectedColors.count < targetCount && selectedColors.count < clusters.count {
            let remaining = clusters.filter { cluster in
                !selectedColors.contains(where: { $0 == cluster })
            }
            if let next = remaining.first {
                selectedColors.append(next)
            } else {
                break
            }
        }
        
        return selectedColors
    }
    
    private func sortByVisualProminence(colors: [(r: Int, g: Int, b: Int)], pixelData: [(r: Int, g: Int, b: Int)]) -> [(r: Int, g: Int, b: Int)] {
        var colorProminence: [(color: (r: Int, g: Int, b: Int), prominence: Double)] = []
        
        for color in colors {
            let frequency = pixelData.filter { perceptualColorDistance($0, color) < 30.0 }.count
            let frequencyScore = Double(frequency) / Double(pixelData.count)
            
            let hsl = rgbToHSL(color)
            
            let prominence = frequencyScore * (1.0 + hsl.s)
            
            colorProminence.append((color: color, prominence: prominence))
        }
        
        return colorProminence.sorted { $0.prominence > $1.prominence }.map { $0.color }
    }
    
    private func perceptualColorDistance(_ c1: (r: Int, g: Int, b: Int), _ c2: (r: Int, g: Int, b: Int)) -> Double {
        let lab1 = rgbToLAB(c1)
        let lab2 = rgbToLAB(c2)
        
        let deltaL = lab1.l - lab2.l
        let deltaA = lab1.a - lab2.a
        let deltaB = lab1.b - lab2.b
        
        return sqrt((deltaL * 0.5) * (deltaL * 0.5) + deltaA * deltaA + deltaB * deltaB)
    }
    
    private func rgbToLAB(_ rgb: (r: Int, g: Int, b: Int)) -> (l: Double, a: Double, b: Double) {
        var r = Double(rgb.r) / 255.0
        var g = Double(rgb.g) / 255.0
        var b = Double(rgb.b) / 255.0
        
        r = r > 0.04045 ? pow((r + 0.055) / 1.055, 2.4) : r / 12.92
        g = g > 0.04045 ? pow((g + 0.055) / 1.055, 2.4) : g / 12.92
        b = b > 0.04045 ? pow((b + 0.055) / 1.055, 2.4) : b / 12.92
        
        let x = r * 0.4124 + g * 0.3576 + b * 0.1805
        let y = r * 0.2126 + g * 0.7152 + b * 0.0722
        let z = r * 0.0193 + g * 0.1192 + b * 0.9505
        
        let xn = x / 0.95047
        let yn = y / 1.00000
        let zn = z / 1.08883
        
        func labFunc(_ t: Double) -> Double {
            return t > 0.008856 ? pow(t, 1.0/3.0) : (7.787 * t) + (16.0 / 116.0)
        }
        
        let fx = labFunc(xn)
        let fy = labFunc(yn)
        let fz = labFunc(zn)
        
        let l = (116.0 * fy) - 16.0
        let a = 500.0 * (fx - fy)
        let bLab = 200.0 * (fy - fz)
        
        return (l: l, a: a, b: bLab)
    }
    
    private func rgbToHSL(_ rgb: (r: Int, g: Int, b: Int)) -> (h: Double, s: Double, l: Double) {
        let r = Double(rgb.r) / 255.0
        let g = Double(rgb.g) / 255.0
        let b = Double(rgb.b) / 255.0
        
        let maxVal = max(r, g, b)
        let minVal = min(r, g, b)
        let delta = maxVal - minVal
        
        let l = (maxVal + minVal) / 2.0
        
        var s = 0.0
        if delta != 0 {
            s = l < 0.5 ? delta / (maxVal + minVal) : delta / (2.0 - maxVal - minVal)
        }
        
        var h = 0.0
        if delta != 0 {
            if maxVal == r {
                h = ((g - b) / delta) + (g < b ? 6.0 : 0.0)
            } else if maxVal == g {
                h = ((b - r) / delta) + 2.0
            } else {
                h = ((r - g) / delta) + 4.0
            }
            h *= 60.0
        }
        
        return (h: h, s: s, l: l * 255.0)
    }
    
    private func luminance(_ color: (r: Int, g: Int, b: Int)) -> Double {
        return 0.299 * Double(color.r) + 0.587 * Double(color.g) + 0.114 * Double(color.b)
    }
    
    private func rgbToHex(_ color: (r: Int, g: Int, b: Int)) -> String {
        return String(format: "#%02X%02X%02X", color.r, color.g, color.b)
    }
    
    private func defaultColors() -> [String] {
        return ["#E74C3C", "#3498DB", "#2ECC71", "#F39C12", "#9B59B6", "#1ABC9C"]
    }
    
    private func defaultRGBColors() -> [(r: Int, g: Int, b: Int)] {
        return [
            (r: 231, g: 76, b: 60),
            (r: 52, g: 152, b: 219),
            (r: 46, g: 204, b: 113),
            (r: 243, g: 156, b: 18),
            (r: 155, g: 89, b: 182),
            (r: 26, g: 188, b: 156)
        ]
    }
}

extension ColorExtractionService {
    fileprivate func colorsAreEqual(_ c1: (r: Int, g: Int, b: Int), _ c2: (r: Int, g: Int, b: Int)) -> Bool {
        return c1.r == c2.r && c1.g == c2.g && c1.b == c2.b
    }
}
