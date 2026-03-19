import Foundation

/// Downloads remote videos for analysis
final class VideoDownloader {

    /// Supported video MIME types
    private static let videoMIMETypes: Set<String> = [
        "video/mp4", "video/quicktime", "video/x-msvideo",
        "video/webm", "video/mpeg", "video/3gpp",
        "video/x-matroska", "video/x-flv",
        "application/octet-stream"
    ]

    /// Streaming/social platform hosts that don't serve direct video files
    private static let unsupportedHosts: [String] = [
        "youtube.com", "www.youtube.com", "m.youtube.com",
        "youtu.be",
        "vimeo.com", "www.vimeo.com",
        "tiktok.com", "www.tiktok.com",
        "instagram.com", "www.instagram.com",
        "facebook.com", "www.facebook.com", "fb.watch",
        "twitter.com", "www.twitter.com", "x.com",
        "dailymotion.com", "www.dailymotion.com",
        "twitch.tv", "www.twitch.tv", "clips.twitch.tv"
    ]

    /// Check if a URL is from an unsupported streaming platform
    static func validateURL(_ url: URL) throws {
        guard let host = url.host?.lowercased() else {
            throw VideoDownloadError.invalidURL
        }

        if unsupportedHosts.contains(host) {
            throw VideoDownloadError.unsupportedPlatform(host: host)
        }
    }

    /// Download a video from a URL to a temporary local file
    /// - Parameter url: The remote URL of the video
    /// - Returns: Local file URL of the downloaded video
    static func download(from url: URL) async throws -> URL {
        // Validate URL is not from an unsupported platform
        try validateURL(url)

        let (tempURL, response) = try await URLSession.shared.download(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            try? FileManager.default.removeItem(at: tempURL)
            throw VideoDownloadError.downloadFailed
        }

        // Verify the response contains video content
        if let mimeType = httpResponse.mimeType?.lowercased(),
           !videoMIMETypes.contains(mimeType) {
            try? FileManager.default.removeItem(at: tempURL)
            throw VideoDownloadError.notAVideoFile
        }

        // Determine file extension from response
        let fileExtension = determineExtension(from: response, url: url)

        // Move to a persistent temporary location
        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(fileExtension)

        try FileManager.default.moveItem(at: tempURL, to: destinationURL)

        return destinationURL
    }

    /// Clean up a downloaded temporary file
    static func cleanup(localURL: URL) {
        try? FileManager.default.removeItem(at: localURL)
    }

    private static func determineExtension(from response: URLResponse, url: URL) -> String {
        // Try to get extension from Content-Type header
        if let mimeType = response.mimeType {
            switch mimeType {
            case "video/mp4":
                return "mp4"
            case "video/quicktime":
                return "mov"
            case "video/x-msvideo":
                return "avi"
            case "video/webm":
                return "webm"
            default:
                break
            }
        }

        // Fall back to URL path extension
        let pathExtension = url.pathExtension.lowercased()
        if !pathExtension.isEmpty {
            return pathExtension
        }

        // Default to mp4
        return "mp4"
    }
}

/// Errors that can occur during video download
enum VideoDownloadError: LocalizedError {
    case downloadFailed
    case invalidURL
    case unsupportedPlatform(host: String)
    case notAVideoFile

    var errorDescription: String? {
        switch self {
        case .downloadFailed:
            return "Failed to download the video. Please check the URL and try again."
        case .invalidURL:
            return "The provided URL is not valid."
        case .unsupportedPlatform(let host):
            return "\(host) links are not supported. Please provide a direct link to a video file (e.g. https://example.com/video.mp4). You can download the video first, then upload it from your photo library."
        case .notAVideoFile:
            return "The URL does not point to a video file. Please provide a direct link to a video file (MP4, MOV, AVI, or WebM)."
        }
    }
}
