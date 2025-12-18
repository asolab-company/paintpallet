import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var progress: CGFloat = 0
    
    let duration: Double
    
    init(duration: Double = Double.random(in: 1...5)) {
        self.duration = duration
    }
    
    var body: some View {
        GeometryReader { geometry in
            let iconSize = min(geometry.size.width * 0.65, geometry.size.height * 0.35)
            
            ZStack {
                // Background gradient
                AppColors.radialBackground(geometry: geometry)
                    .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App logo/icon
                Image("app-icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                // App name
                VStack(spacing: 8) {
                    Text("Palette Maker")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Extract beautiful colors")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .opacity(logoOpacity)
                
                // Progress bar - NO percentage text
                VStack(spacing: 12) {
                    // Progress bar container
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 12)
                            
                            // Animated progress fill with gradient
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppColors.buttonGradient)
                                .frame(width: geometry.size.width * progress, height: 12)
                        }
                    }
                    .frame(height: 12)
                    .frame(width: 200)
                }
                .padding(.top, 40)
                .opacity(logoOpacity)
            }
            }
        }
        .onAppear {
            // Animate logo appearance
            withAnimation(.easeOut(duration: 0.8)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            // Glow animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
            
            // Start non-linear progress animation
            startRealisticProgressAnimation()
        }
    }
    
    private func startRealisticProgressAnimation() {
        Task {
            var currentProgress: CGFloat = 0
            let totalDuration = duration
            
            let segments: [(targetProgress: CGFloat, speedFactor: Double, pauseAfter: Double)] = [
                (0.12 + CGFloat.random(in: 0...0.08), 0.8, Double.random(in: 0.1...0.25)),
                (0.28 + CGFloat.random(in: 0...0.07), 1.2, Double.random(in: 0.15...0.35)),
                (0.45 + CGFloat.random(in: 0...0.10), 0.6, Double.random(in: 0.2...0.4)),
                (0.58 + CGFloat.random(in: 0...0.07), 1.5, Double.random(in: 0.1...0.3)),
                (0.75 + CGFloat.random(in: 0...0.08), 0.7, Double.random(in: 0.15...0.35)),
                (0.88 + CGFloat.random(in: 0...0.05), 1.3, Double.random(in: 0.1...0.2)),
                (1.0, 0.5, 0)
            ]
            
            let totalPauseTime = segments.reduce(0) { $0 + $1.pauseAfter }
            let animationTime = totalDuration - totalPauseTime * 0.5
            let timePerSegment = animationTime / Double(segments.count)
            
            for segment in segments {
                let targetProgress = min(segment.targetProgress, 1.0)
                let progressDelta = targetProgress - currentProgress
                
                let steps = Int.random(in: 4...8)
                let stepDuration = (timePerSegment * segment.speedFactor) / Double(steps)
                
                for step in 1...steps {
                    let stepProgress = currentProgress + (progressDelta * CGFloat(step) / CGFloat(steps))
                    
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: stepDuration)) {
                            progress = stepProgress
                        }
                    }
                    
                    try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
                }
                
                currentProgress = targetProgress
                
                if segment.pauseAfter > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(segment.pauseAfter * 0.5 * 1_000_000_000))
                }
                
                if Bool.random() && currentProgress < 0.9 {
                    try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 0.05...0.15) * 1_000_000_000))
                }
            }
            
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    progress = 1.0
                }
            }
        }
    }
}

#Preview {
    SplashScreenView(duration: 3.0)
}
