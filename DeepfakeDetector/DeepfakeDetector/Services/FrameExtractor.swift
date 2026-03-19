import AVFoundation
import UIKit

/// Extracts frames from a video for analysis
final class FrameExtractor {

    /// Extract frames at regular intervals from a video
    /// - Parameters:
    ///   - url: The URL of the video file
    ///   - maxFrames: Maximum number of frames to extract
    /// - Returns: Array of extracted CGImage frames
    static func extractFrames(from url: URL, maxFrames: Int = 30) async throws -> [CGImage] {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)

        guard durationSeconds > 0 else {
            throw FrameExtractionError.invalidVideo
        }

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.1, preferredTimescale: 600)
        generator.maximumSize = CGSize(width: 640, height: 640)

        let frameCount = min(maxFrames, Int(durationSeconds * 2))
        let interval = durationSeconds / Double(frameCount)

        var frames: [CGImage] = []

        for i in 0..<frameCount {
            let time = CMTime(seconds: Double(i) * interval, preferredTimescale: 600)
            do {
                let (image, _) = try await generator.image(at: time)
                frames.append(image)
            } catch {
                continue
            }
        }

        guard !frames.isEmpty else {
            throw FrameExtractionError.noFramesExtracted
        }

        return frames
    }

    /// Get video metadata
    static func getVideoMetadata(from url: URL) async throws -> VideoMetadata {
        let asset = AVURLAsset(url: url)

        let duration = try await asset.load(.duration)
        let tracks = try await asset.load(.tracks)

        var resolution: CGSize = .zero
        var frameRate: Float = 0
        var codec: String = "Unknown"
        var hasAudio = false

        for track in tracks {
            let mediaType = track.mediaType
            if mediaType == .video {
                let size = try await track.load(.naturalSize)
                let nominalFR = try await track.load(.nominalFrameRate)
                resolution = size
                frameRate = nominalFR

                let formatDescriptions = try await track.load(.formatDescriptions)
                if let formatDesc = formatDescriptions.first {
                    let codecType = CMFormatDescriptionGetMediaSubType(formatDesc)
                    codec = fourCharCodeToString(codecType)
                }
            } else if mediaType == .audio {
                hasAudio = true
            }
        }

        return VideoMetadata(
            duration: CMTimeGetSeconds(duration),
            resolution: resolution,
            frameRate: frameRate,
            codec: codec,
            hasAudio: hasAudio,
            fileSize: getFileSize(url: url)
        )
    }

    private static func fourCharCodeToString(_ code: FourCharCode) -> String {
        let bytes: [CChar] = [
            CChar(truncatingIfNeeded: (code >> 24) & 0xFF),
            CChar(truncatingIfNeeded: (code >> 16) & 0xFF),
            CChar(truncatingIfNeeded: (code >> 8) & 0xFF),
            CChar(truncatingIfNeeded: code & 0xFF),
            0
        ]
        return String(cString: bytes)
    }

    private static func getFileSize(url: URL) -> Int64 {
        guard url.isFileURL else { return 0 }
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
}

/// Video metadata information
struct VideoMetadata {
    let duration: Double
    let resolution: CGSize
    let frameRate: Float
    let codec: String
    let hasAudio: Bool
    let fileSize: Int64

    var resolutionString: String {
        "\(Int(resolution.width))x\(Int(resolution.height))"
    }

    var fileSizeString: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}

/// Errors that can occur during frame extraction
enum FrameExtractionError: LocalizedError {
    case invalidVideo
    case noFramesExtracted

    var errorDescription: String? {
        switch self {
        case .invalidVideo:
            return "The video file is invalid or cannot be read."
        case .noFramesExtracted:
            return "No frames could be extracted from the video."
        }
    }
}
