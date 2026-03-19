import SwiftUI

/// View displaying analysis results
struct ResultView: View {
    let result: AnalysisResult
    let thumbnail: UIImage?
    let onReset: () -> Void

    @State private var showDetails = false

    var verdictColor: Color {
        Color.forVerdict(result.verdict)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Video thumbnail
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(verdictColor.opacity(0.5), lineWidth: 2)
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                }

                // Verdict Card
                VStack(spacing: 16) {
                    Image(systemName: result.verdict.emoji)
                        .font(.system(size: 50))
                        .foregroundColor(verdictColor)

                    Text(result.verdict.rawValue)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(verdictColor)

                    Text(result.verdict.description)
                        .font(.subheadline)
                        .foregroundColor(.subtitleText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(verdictColor.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)

                // Confidence Score
                ConfidenceGauge(score: result.confidenceScore, color: verdictColor)
                    .padding(.horizontal, 24)

                // Summary
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.accentGlow)
                    Text(result.summary)
                        .font(.caption)
                        .foregroundColor(.subtitleText)
                }
                .padding(.horizontal, 32)

                // Detailed Metrics
                VStack(spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showDetails.toggle()
                        }
                    } label: {
                        HStack {
                            Text("Detailed Analysis")
                                .font(.headline)
                                .foregroundColor(.white)

                            Spacer()

                            Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                                .foregroundColor(.subtitleText)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.cardBackground)
                        )
                    }

                    if showDetails {
                        VStack(spacing: 8) {
                            ForEach(
                                Array(result.metrics.allMetrics.enumerated()),
                                id: \.offset
                            ) { _, metric in
                                MetricRow(
                                    name: metric.name,
                                    score: metric.score,
                                    description: metric.description
                                )
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 24)

                // Analyze Another Button
                Button(action: onReset) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Analyze Another Video")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.accentGlow, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Confidence Gauge

struct ConfidenceGauge: View {
    let score: Double
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Text("Confidence")
                .font(.subheadline)
                .foregroundColor(.subtitleText)

            ZStack {
                Circle()
                    .stroke(Color.cardBackground, lineWidth: 10)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: score)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                Text(String(format: "%.0f%%", score * 100))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
        )
    }
}

// MARK: - Metric Row

struct MetricRow: View {
    let name: String
    let score: Double
    let description: String

    @State private var showTooltip = false

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(name)
                    .font(.subheadline)
                    .foregroundColor(.white)

                Button {
                    withAnimation {
                        showTooltip.toggle()
                    }
                } label: {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.subtitleText)
                }

                Spacer()

                Text(String(format: "%.0f%%", score * 100))
                    .font(.subheadline.monospacedDigit().bold())
                    .foregroundColor(Color.forScore(score))
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.appBackground)
                        .frame(height: 6)

                    Capsule()
                        .fill(Color.forScore(score))
                        .frame(width: geometry.size.width * score, height: 6)
                }
            }
            .frame(height: 6)

            if showTooltip {
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.subtitleText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.cardBackground)
        )
    }
}

#Preview {
    let metrics = DetectionMetrics(
        frameConsistencyScore: 0.85,
        temporalCoherenceScore: 0.72,
        metadataScore: 0.90,
        compressionArtifactScore: 0.65,
        facialConsistencyScore: 0.78,
        motionPatternScore: 0.80,
        audioVisualSyncScore: 0.75
    )

    let result = AnalysisResult(
        verdict: .real,
        confidenceScore: 0.87,
        metrics: metrics,
        analyzedFrameCount: 30,
        videoDuration: 15.0,
        analysisTimestamp: Date()
    )

    ZStack {
        Color.appBackground.ignoresSafeArea()
        ResultView(result: result, thumbnail: nil, onReset: {})
    }
}
