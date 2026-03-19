import Foundation

/// Detailed metrics from the video analysis process
struct DetectionMetrics {
    /// Score indicating frame-to-frame visual consistency (0.0 = inconsistent, 1.0 = consistent)
    let frameConsistencyScore: Double

    /// Score indicating temporal coherence across the video (0.0 = incoherent, 1.0 = coherent)
    let temporalCoherenceScore: Double

    /// Score from analyzing video metadata for anomalies (0.0 = suspicious, 1.0 = normal)
    let metadataScore: Double

    /// Score from analyzing compression artifacts (0.0 = heavy artifacts, 1.0 = natural compression)
    let compressionArtifactScore: Double

    /// Score from analyzing facial consistency if faces are detected (0.0 = inconsistent, 1.0 = consistent)
    let facialConsistencyScore: Double?

    /// Score from analyzing motion patterns (0.0 = unnatural, 1.0 = natural)
    let motionPatternScore: Double

    /// Score from analyzing audio-visual sync if audio is present (0.0 = out of sync, 1.0 = in sync)
    let audioVisualSyncScore: Double?

    /// All metric items for display
    var allMetrics: [(name: String, score: Double, description: String)] {
        var items: [(String, Double, String)] = [
            ("Frame Consistency", frameConsistencyScore,
             "Measures visual consistency between consecutive frames"),
            ("Temporal Coherence", temporalCoherenceScore,
             "Analyzes natural flow and continuity over time"),
            ("Metadata Analysis", metadataScore,
             "Checks video metadata for signs of AI generation"),
            ("Compression Artifacts", compressionArtifactScore,
             "Evaluates compression patterns for anomalies"),
            ("Motion Patterns", motionPatternScore,
             "Analyzes natural vs synthetic motion characteristics")
        ]

        if let facialScore = facialConsistencyScore {
            items.append(("Facial Consistency", facialScore,
                         "Checks facial features for deepfake artifacts"))
        }

        if let avSync = audioVisualSyncScore {
            items.append(("Audio-Visual Sync", avSync,
                         "Measures synchronization between audio and video"))
        }

        return items
    }

    /// Overall weighted score combining all metrics
    var overallScore: Double {
        var totalWeight: Double = 0
        var weightedSum: Double = 0

        let weights: [(Double, Double)] = [
            (frameConsistencyScore, 0.20),
            (temporalCoherenceScore, 0.20),
            (metadataScore, 0.10),
            (compressionArtifactScore, 0.15),
            (motionPatternScore, 0.15)
        ]

        for (score, weight) in weights {
            weightedSum += score * weight
            totalWeight += weight
        }

        if let facialScore = facialConsistencyScore {
            weightedSum += facialScore * 0.15
            totalWeight += 0.15
        }

        if let avSync = audioVisualSyncScore {
            weightedSum += avSync * 0.05
            totalWeight += 0.05
        }

        return totalWeight > 0 ? weightedSum / totalWeight : 0.5
    }
}
