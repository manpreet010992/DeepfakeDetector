import SwiftUI

extension Color {
    /// App theme colors
    static let appBackground = Color(red: 0.05, green: 0.05, blue: 0.12)
    static let cardBackground = Color(red: 0.10, green: 0.10, blue: 0.18)
    static let accentGlow = Color(red: 0.30, green: 0.50, blue: 1.0)
    static let verdictReal = Color(red: 0.20, green: 0.80, blue: 0.40)
    static let verdictFake = Color(red: 1.0, green: 0.30, blue: 0.30)
    static let verdictInconclusive = Color(red: 1.0, green: 0.75, blue: 0.20)
    static let subtitleText = Color(red: 0.60, green: 0.60, blue: 0.70)

    /// Get color for a metric score
    static func forScore(_ score: Double) -> Color {
        if score >= 0.7 {
            return .verdictReal
        } else if score >= 0.4 {
            return .verdictInconclusive
        } else {
            return .verdictFake
        }
    }

    /// Get color for a verdict
    static func forVerdict(_ verdict: VideoVerdict) -> Color {
        switch verdict {
        case .real:
            return .verdictReal
        case .aiGenerated:
            return .verdictFake
        case .inconclusive:
            return .verdictInconclusive
        }
    }
}
