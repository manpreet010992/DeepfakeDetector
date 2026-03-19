import Foundation

/// Downloads remote videos for analysis
final class VideoDownloader {

    /// Download a video from a URL to a temporary local file
    /// - Parameter url: The remote URL of the video
    /// - Returns: Local file URL of the downloaded video
    static func download(from url: URL) async throws -> URL {
        let (tempURL, response) = try await URLSession.shared.download(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            try? FileManager.default.removeItem(at: tempURL)
            throw VideoDownloadError.downloadFailed
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

    var errorDescription: String? {
        switch self {
        case .downloadFailed:
            return "Failed to download the video. Please check the URL and try again."
        case .invalidURL:
            return "The provided URL is not valid."
        }
    }
}
