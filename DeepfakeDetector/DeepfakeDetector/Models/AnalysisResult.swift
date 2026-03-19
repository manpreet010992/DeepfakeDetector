import Foundation

/// The overall verdict of the video analysis
enum VideoVerdict: String {
    case real = "Real"
    case aiGenerated = "AI Generated"
    case inconclusive = "Inconclusive"

    var emoji: String {
        switch self {
        case .real:
            return "checkmark.shield.fill"
        case .aiGenerated:
            return "exclamationmark.triangle.fill"
        case .inconclusive:
            return "questionmark.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .real:
            return "This video appears to be authentic and naturally captured."
        case .aiGenerated:
            return "This video shows signs of being generated or manipulated by AI."
        case .inconclusive:
            return "Unable to determine with sufficient confidence. Consider uploading a higher quality video."
        }
    }
}

/// Holds the complete result of a video analysis
struct AnalysisResult: Identifiable {
    let id = UUID()
    let verdict: VideoVerdict
    let confidenceScore: Double
    let metrics: DetectionMetrics
    let analyzedFrameCount: Int
    let videoDuration: Double
    let analysisTimestamp: Date

    /// Confidence as a percentage string
    var confidencePercentage: String {
        String(format: "%.1f%%", confidenceScore * 100)
    }

    /// Human-readable analysis summary
    var summary: String {
        "Analyzed \(analyzedFrameCount) frames over \(String(format: "%.1f", videoDuration))s of video. Confidence: \(confidencePercentage)"
    }
}
