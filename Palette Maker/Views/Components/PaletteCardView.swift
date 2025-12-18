import SwiftUI

struct PaletteCardView: View {
    let palette: Palette
    let onCopyColor: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Color bars (70% height)
            HStack(spacing: 0) {
                ForEach(Array(palette.colors.enumerated()), id: \.offset) { index, hex in
                    Palette.color(from: hex)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(height: 140)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 16,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 16
                )
            )
            
            // Hex codes and copy buttons (30% height)
            VStack(spacing: 8) {
                // Hex codes row
                HStack(spacing: 4) {
                    ForEach(Array(palette.colors.enumerated()), id: \.offset) { index, hex in
                        Text(formatHex(hex))
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                
                // Copy buttons row
                HStack(spacing: 4) {
                    ForEach(Array(palette.colors.enumerated()), id: \.offset) { index, hex in
                        CopyButton {
                            onCopyColor(hex)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(
                GeometryReader { geo in
                    RadialGradient(
                        colors: [Color(hex: "8C000D"), Color(hex: "160002")],
                        center: UnitPoint(x: 0.5013, y: 0.8862),
                        startRadius: 0,
                        endRadius: max(geo.size.width, geo.size.height) * 2.0
                    )
                }
            )
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 16,
                    bottomTrailingRadius: 16,
                    topTrailingRadius: 0
                )
            )
        }
        .background(
            GeometryReader { geo in
                RadialGradient(
                    colors: [Color(hex: "8C000D"), Color(hex: "160002")],
                    center: UnitPoint(x: 0.5013, y: 0.8862),
                    startRadius: 0,
                    endRadius: max(geo.size.width, geo.size.height) * 2.0
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func formatHex(_ hex: String) -> String {
        let clean = hex.hasPrefix("#") ? hex : "#\(hex)"
        return clean.uppercased()
    }
}

struct ColorPaletteView: View {
    let colors: [String]
    let onCopyColor: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Color bars
            HStack(spacing: 0) {
                ForEach(Array(colors.enumerated()), id: \.offset) { index, hex in
                    Palette.color(from: hex)
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                }
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 12,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 12
                )
            )
            
            // Hex codes and copy buttons
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    ForEach(Array(colors.enumerated()), id: \.offset) { index, hex in
                        Text(formatHex(hex))
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                
                HStack(spacing: 4) {
                    ForEach(Array(colors.enumerated()), id: \.offset) { index, hex in
                        CopyButton {
                            onCopyColor(hex)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .background(
                GeometryReader { geo in
                    RadialGradient(
                        colors: [Color(hex: "8C000D"), Color(hex: "160002")],
                        center: UnitPoint(x: 0.5013, y: 0.8862),
                        startRadius: 0,
                        endRadius: max(geo.size.width, geo.size.height) * 2.0
                    )
                }
            )
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 12,
                    bottomTrailingRadius: 12,
                    topTrailingRadius: 0
                )
            )
        }
        .background(
            GeometryReader { geo in
                RadialGradient(
                    colors: [Color(hex: "8C000D"), Color(hex: "160002")],
                    center: UnitPoint(x: 0.5013, y: 0.8862),
                    startRadius: 0,
                    endRadius: max(geo.size.width, geo.size.height) * 2.0
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
    }
    
    private func formatHex(_ hex: String) -> String {
        let clean = hex.hasPrefix("#") ? hex : "#\(hex)"
        return clean.uppercased()
    }
}

#Preview {
    VStack(spacing: 20) {
        PaletteCardView(
            palette: Palette(
                colors: ["#2C3E50", "#E74C3C", "#3498DB", "#2ECC71", "#F39C12", "#9B59B6"]
            ),
            onCopyColor: { _ in }
        )
        
        ColorPaletteView(
            colors: ["#2C3E50", "#E74C3C", "#3498DB", "#2ECC71", "#F39C12", "#9B59B6"],
            onCopyColor: { _ in }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
