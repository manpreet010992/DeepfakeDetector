import AVFoundation
import CoreImage
import UIKit

/// Service responsible for analyzing videos to detect AI generation
final class VideoAnalysisService {

    /// Analyze a video and return detection results
    /// - Parameters:
    ///   - url: Local URL of the video to analyze
    ///   - progressHandler: Closure called with progress updates (0.0 to 1.0)
    /// - Returns: The analysis result
    func analyze(
        videoURL url: URL,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> AnalysisResult {
        progressHandler(0.05)

        // Step 1: Extract video metadata
        let metadata = try await FrameExtractor.getVideoMetadata(from: url)
        progressHandler(0.15)

        // Step 2: Extract frames for analysis
        let frames = try await FrameExtractor.extractFrames(from: url, maxFrames: 30)
        progressHandler(0.40)

        // Step 3: Analyze frame consistency
        let frameConsistency = analyzeFrameConsistency(frames: frames)
        progressHandler(0.55)

        // Step 4: Analyze temporal coherence
        let temporalCoherence = analyzeTemporalCoherence(frames: frames)
        progressHandler(0.65)

        // Step 5: Analyze metadata
        let metadataScore = analyzeMetadata(metadata: metadata)
        progressHandler(0.75)

        // Step 6: Analyze compression artifacts
        let compressionScore = analyzeCompressionArtifacts(frames: frames)
        progressHandler(0.85)

        // Step 7: Analyze motion patterns
        let motionScore = analyzeMotionPatterns(frames: frames)
        progressHandler(0.90)

        // Step 8: Detect faces and analyze facial consistency
        let facialScore = analyzeFacialConsistency(frames: frames)

        // Step 9: Analyze audio-visual sync if audio exists
        let avSyncScore: Double? = metadata.hasAudio ? analyzeAudioVisualSync(url: url) : nil
        progressHandler(0.95)

        // Build metrics
        let metrics = DetectionMetrics(
            frameConsistencyScore: frameConsistency,
            temporalCoherenceScore: temporalCoherence,
            metadataScore: metadataScore,
            compressionArtifactScore: compressionScore,
            facialConsistencyScore: facialScore,
            motionPatternScore: motionScore,
            audioVisualSyncScore: avSyncScore
        )

        // Determine verdict
        let overallScore = metrics.overallScore
        let verdict: VideoVerdict
        let confidence: Double

        if overallScore >= 0.7 {
            verdict = .real
            confidence = min(0.95, overallScore)
        } else if overallScore <= 0.4 {
            verdict = .aiGenerated
            confidence = min(0.95, 1.0 - overallScore)
        } else {
            verdict = .inconclusive
            confidence = 0.5 + abs(overallScore - 0.5)
        }

        progressHandler(1.0)

        return AnalysisResult(
            verdict: verdict,
            confidenceScore: confidence,
            metrics: metrics,
            analyzedFrameCount: frames.count,
            videoDuration: metadata.duration,
            analysisTimestamp: Date()
        )
    }

    // MARK: - Analysis Methods

    /// Analyze consistency between consecutive frames
    private func analyzeFrameConsistency(frames: [CGImage]) -> Double {
        guard frames.count >= 2 else { return 0.5 }

        var consistencyScores: [Double] = []

        for i in 1..<frames.count {
            let score = compareFrames(frames[i - 1], frames[i])
            consistencyScores.append(score)
        }

        // Natural videos have gradual changes; AI videos may have sudden inconsistencies
        let averageScore = consistencyScores.reduce(0.0, +) / Double(consistencyScores.count)
        let variance = consistencyScores.map { pow($0 - averageScore, 2) }.reduce(0.0, +)
            / Double(consistencyScores.count)

        // Low variance + reasonable average = likely real
        // High variance or extreme average = possibly AI
        let varianceScore = max(0, 1.0 - variance * 10)
        return (averageScore * 0.6 + varianceScore * 0.4)
    }

    /// Analyze temporal coherence across the video
    private func analyzeTemporalCoherence(frames: [CGImage]) -> Double {
        guard frames.count >= 3 else { return 0.5 }

        var coherenceScores: [Double] = []

        // Check if motion is smooth by comparing frame-to-frame differences
        for i in 2..<frames.count {
            let diff1 = frameDifference(frames[i - 2], frames[i - 1])
            let diff2 = frameDifference(frames[i - 1], frames[i])

            // In natural videos, consecutive frame differences should be similar
            let coherence = 1.0 - min(1.0, abs(diff1 - diff2) * 5)
            coherenceScores.append(coherence)
        }

        return coherenceScores.reduce(0.0, +) / Double(coherenceScores.count)
    }

    /// Analyze video metadata for signs of AI generation
    private func analyzeMetadata(metadata: VideoMetadata) -> Double {
        var score: Double = 0.8

        // Check for standard frame rates (AI often uses non-standard)
        let standardFrameRates: [Float] = [23.976, 24.0, 25.0, 29.97, 30.0, 50.0, 59.94, 60.0]
        let isStandardFrameRate = standardFrameRates.contains { abs($0 - metadata.frameRate) < 0.5 }
        if !isStandardFrameRate && metadata.frameRate > 0 {
            score -= 0.2
        }

        // Check resolution - very unusual resolutions may indicate AI
        let standardWidths: [CGFloat] = [640, 720, 1080, 1280, 1920, 2560, 3840]
        let isStandardWidth = standardWidths.contains { abs($0 - metadata.resolution.width) < 20 }
        if !isStandardWidth && metadata.resolution.width > 0 {
            score -= 0.1
        }

        // Check codec - AI-generated videos may use specific codecs
        let commonCodecs = ["avc1", "hvc1", "mp4v", "H264", "HEVC"]
        if !commonCodecs.contains(where: { metadata.codec.contains($0) }) {
            score -= 0.1
        }

        // Very short videos with no audio are more suspicious
        if metadata.duration < 5 && !metadata.hasAudio {
            score -= 0.1
        }

        return max(0.0, min(1.0, score))
    }

    /// Analyze compression artifacts in frames
    private func analyzeCompressionArtifacts(frames: [CGImage]) -> Double {
        guard !frames.isEmpty else { return 0.5 }

        var artifactScores: [Double] = []

        for frame in frames.prefix(10) {
            let score = analyzeBlockiness(frame: frame)
            artifactScores.append(score)
        }

        return artifactScores.reduce(0.0, +) / Double(artifactScores.count)
    }

    /// Analyze motion patterns for naturalness
    private func analyzeMotionPatterns(frames: [CGImage]) -> Double {
        guard frames.count >= 5 else { return 0.5 }

        var motionMagnitudes: [Double] = []

        for i in 1..<min(frames.count, 20) {
            let magnitude = frameDifference(frames[i - 1], frames[i])
            motionMagnitudes.append(magnitude)
        }

        guard !motionMagnitudes.isEmpty else { return 0.5 }

        // Natural motion follows smooth acceleration/deceleration patterns
        let avgMotion = motionMagnitudes.reduce(0.0, +) / Double(motionMagnitudes.count)

        // Check for unnatural sudden changes in motion
        var smoothnessScore: Double = 1.0
        for i in 1..<motionMagnitudes.count {
            let change = abs(motionMagnitudes[i] - motionMagnitudes[i - 1])
            if change > avgMotion * 2 {
                smoothnessScore -= 0.1
            }
        }

        return max(0.0, min(1.0, smoothnessScore))
    }

    /// Analyze facial consistency across frames (simplified)
    private func analyzeFacialConsistency(frames: [CGImage]) -> Double? {
        // Use CIDetector for basic face detection
        let context = CIContext()
        let detector = CIDetector(
            ofType: CIDetectorTypeFace,
            context: context,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        )

        var faceCountsPerFrame: [Int] = []
        var faceSizesPerFrame: [CGFloat] = []

        for frame in frames.prefix(15) {
            let ciImage = CIImage(cgImage: frame)
            let features = detector?.features(in: ciImage) ?? []
            faceCountsPerFrame.append(features.count)

            if let firstFace = features.first {
                faceSizesPerFrame.append(firstFace.bounds.width)
            }
        }

        // If no faces detected, return nil (not applicable)
        guard faceCountsPerFrame.contains(where: { $0 > 0 }) else {
            return nil
        }

        // Check face count consistency
        let maxFaceCount = faceCountsPerFrame.max() ?? 0
        let minFaceCount = faceCountsPerFrame.filter { $0 > 0 }.min() ?? 0
        let countConsistency = maxFaceCount == minFaceCount ? 1.0 : 0.7

        // Check face size consistency (should be gradual changes)
        var sizeConsistency: Double = 1.0
        if faceSizesPerFrame.count >= 2 {
            for i in 1..<faceSizesPerFrame.count {
                let change = abs(faceSizesPerFrame[i] - faceSizesPerFrame[i - 1])
                    / max(faceSizesPerFrame[i], 1)
                if change > 0.3 {
                    sizeConsistency -= 0.15
                }
            }
        }

        return max(0.0, (countConsistency * 0.5 + max(0, sizeConsistency) * 0.5))
    }

    /// Analyze audio-visual synchronization (simplified)
    private func analyzeAudioVisualSync(url: URL) -> Double {
        // Simplified: return a moderate score
        // A full implementation would analyze audio waveform against visual motion
        return 0.75
    }

    // MARK: - Helper Methods

    /// Compare two frames and return a similarity score (0 = different, 1 = identical)
    private func compareFrames(_ frame1: CGImage, _ frame2: CGImage) -> Double {
        let size = CGSize(width: 64, height: 64)

        guard let data1 = resizeAndGetPixelData(frame1, size: size),
              let data2 = resizeAndGetPixelData(frame2, size: size) else {
            return 0.5
        }

        let pixelCount = Int(size.width * size.height * 4)
        var totalDiff: Double = 0

        for i in 0..<min(data1.count, min(data2.count, pixelCount)) {
            totalDiff += abs(Double(data1[i]) - Double(data2[i]))
        }

        let maxDiff = Double(pixelCount) * 255.0
        let similarity = 1.0 - (totalDiff / maxDiff)

        return similarity
    }

    /// Calculate the difference between two frames
    private func frameDifference(_ frame1: CGImage, _ frame2: CGImage) -> Double {
        return 1.0 - compareFrames(frame1, frame2)
    }

    /// Resize an image and extract pixel data
    private func resizeAndGetPixelData(_ image: CGImage, size: CGSize) -> [UInt8]? {
        let width = Int(size.width)
        let height = Int(size.height)
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(image, in: CGRect(origin: .zero, size: size))
        return pixelData
    }

    /// Analyze blockiness in a frame (sign of heavy compression or AI artifacts)
    private func analyzeBlockiness(frame: CGImage) -> Double {
        let size = CGSize(width: 128, height: 128)

        guard let data = resizeAndGetPixelData(frame, size: size) else {
            return 0.5
        }

        let width = Int(size.width)
        let height = Int(size.height)
        var edgeStrength: Double = 0
        var blockBoundaryStrength: Double = 0
        let blockSize = 8

        // Compare edge strengths at block boundaries vs non-boundaries
        for y in 1..<height {
            for x in 1..<width {
                let idx = (y * width + x) * 4
                let leftIdx = (y * width + (x - 1)) * 4
                let topIdx = ((y - 1) * width + x) * 4

                guard idx + 2 < data.count && leftIdx + 2 < data.count && topIdx + 2 < data.count else {
                    continue
                }

                let hDiff = abs(Int(data[idx]) - Int(data[leftIdx]))
                    + abs(Int(data[idx + 1]) - Int(data[leftIdx + 1]))
                    + abs(Int(data[idx + 2]) - Int(data[leftIdx + 2]))

                let vDiff = abs(Int(data[idx]) - Int(data[topIdx]))
                    + abs(Int(data[idx + 1]) - Int(data[topIdx + 1]))
                    + abs(Int(data[idx + 2]) - Int(data[topIdx + 2]))

                let totalDiff = Double(hDiff + vDiff)

                if x % blockSize == 0 || y % blockSize == 0 {
                    blockBoundaryStrength += totalDiff
                } else {
                    edgeStrength += totalDiff
                }
            }
        }

        // Normalize
        let totalPixels = Double(width * height)
        let normalizedBlock = blockBoundaryStrength / totalPixels
        let normalizedEdge = edgeStrength / totalPixels

        // High ratio of block boundary edges to regular edges suggests artificial patterns
        let ratio = normalizedEdge > 0 ? normalizedBlock / normalizedEdge : 1.0

        // A ratio close to 1.0 is natural; significantly higher means blocky artifacts
        return max(0.0, min(1.0, 1.0 - (ratio - 1.0) * 0.5))
    }
}
