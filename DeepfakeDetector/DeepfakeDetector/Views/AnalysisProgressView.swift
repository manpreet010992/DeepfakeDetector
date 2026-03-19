import SwiftUI

/// View showing analysis progress
struct AnalysisProgressView: View {
    let progress: Double

    @State private var isAnimating = false

    var progressText: String {
        if progress < 0.15 {
            return "Extracting metadata..."
        } else if progress < 0.40 {
            return "Extracting video frames..."
        } else if progress < 0.55 {
            return "Analyzing frame consistency..."
        } else if progress < 0.65 {
            return "Checking temporal coherence..."
        } else if progress < 0.75 {
            return "Analyzing metadata patterns..."
        } else if progress < 0.85 {
            return "Detecting compression artifacts..."
        } else if progress < 0.90 {
            return "Evaluating motion patterns..."
        } else if progress < 0.95 {
            return "Scanning for facial anomalies..."
        } else {
            return "Generating results..."
        }
    }

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Animated scanning icon
            ZStack {
                Circle()
                    .stroke(Color.accentGlow.opacity(0.2), lineWidth: 3)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        LinearGradient(
                            colors: [.accentGlow, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        .linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: isAnimating
                    )

                Image(systemName: "video.fill.badge.checkmark")
                    .font(.system(size: 40))
                    .foregroundColor(.accentGlow)
            }

            // Progress info
            VStack(spacing: 16) {
                Text("Analyzing Video")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text(progressText)
                    .font(.subheadline)
                    .foregroundColor(.subtitleText)
                    .animation(.easeInOut, value: progressText)

                // Progress bar
                VStack(spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.cardBackground)
                                .frame(height: 8)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.accentGlow, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: geometry.size.width * progress,
                                    height: 8
                                )
                                .animation(.easeInOut(duration: 0.3), value: progress)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal, 40)

                    Text("\(Int(progress * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.subtitleText)
                }
            }

            Spacer()
            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        AnalysisProgressView(progress: 0.65)
    }
}
