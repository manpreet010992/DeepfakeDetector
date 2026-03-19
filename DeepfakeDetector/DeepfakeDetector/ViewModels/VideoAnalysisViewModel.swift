import Foundation
import PhotosUI
import SwiftUI

/// View model managing the video analysis workflow
@MainActor
final class VideoAnalysisViewModel: ObservableObject {

    enum AnalysisState: Equatable {
        case idle
        case loading
        case analyzing(progress: Double)
        case completed(resultId: UUID)
        case error(message: String)

        static func == (lhs: AnalysisState, rhs: AnalysisState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle):
                return true
            case (.loading, .loading):
                return true
            case (.analyzing(let p1), .analyzing(let p2)):
                return p1 == p2
            case (.completed(let id1), .completed(let id2)):
                return id1 == id2
            case (.error(let m1), .error(let m2)):
                return m1 == m2
            default:
                return false
            }
        }
    }

    @Published var state: AnalysisState = .idle
    @Published var urlString: String = ""
    @Published var selectedVideoItem: PhotosPickerItem?
    @Published var analysisResult: AnalysisResult?
    @Published var videoThumbnail: UIImage?
    @Published var showURLInput: Bool = false

    private let analysisService = VideoAnalysisService()
    private var downloadedFileURL: URL?

    var progress: Double {
        if case .analyzing(let p) = state {
            return p
        }
        return 0
    }

    var isAnalyzing: Bool {
        switch state {
        case .loading, .analyzing:
            return true
        default:
            return false
        }
    }

    var errorMessage: String? {
        if case .error(let message) = state {
            return message
        }
        return nil
    }

    // MARK: - Video Selection

    /// Handle video selected from photo library
    func handleVideoSelection(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }

        state = .loading

        do {
            guard let videoData = try await item.loadTransferable(type: Data.self) else {
                state = .error(message: "Could not load the selected video.")
                return
            }

            // Save to temporary file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mp4")
            try videoData.write(to: tempURL)
            downloadedFileURL = tempURL

            // Generate thumbnail
            await generateThumbnail(from: tempURL)

            // Analyze
            await analyzeVideo(at: tempURL)
        } catch {
            state = .error(message: "Failed to load video: \(error.localizedDescription)")
        }
    }

    /// Handle video URL input
    func analyzeFromURL() async {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            state = .error(message: "Please enter a valid URL.")
            return
        }

        guard let url = URL(string: trimmed),
              url.scheme == "http" || url.scheme == "https" else {
            state = .error(message: "Please enter a valid HTTP or HTTPS URL.")
            return
        }

        state = .loading

        do {
            // Download the video
            let localURL = try await VideoDownloader.download(from: url)
            downloadedFileURL = localURL

            // Generate thumbnail
            await generateThumbnail(from: localURL)

            // Analyze
            await analyzeVideo(at: localURL)
        } catch {
            state = .error(message: "Failed to download video: \(error.localizedDescription)")
        }
    }

    // MARK: - Analysis

    /// Analyze a video at the given local URL
    private func analyzeVideo(at url: URL) async {
        state = .analyzing(progress: 0)

        do {
            let result = try await analysisService.analyze(videoURL: url) { [weak self] progress in
                Task { @MainActor in
                    self?.state = .analyzing(progress: progress)
                }
            }

            analysisResult = result
            state = .completed(resultId: result.id)
        } catch {
            state = .error(message: "Analysis failed: \(error.localizedDescription)")
        }
    }

    /// Generate a thumbnail from the video
    private func generateThumbnail(from url: URL) async {
        do {
            let frames = try await FrameExtractor.extractFrames(from: url, maxFrames: 1)
            if let firstFrame = frames.first {
                videoThumbnail = UIImage(cgImage: firstFrame)
            }
        } catch {
            // Thumbnail generation is non-critical
            videoThumbnail = nil
        }
    }

    // MARK: - Reset

    /// Reset the view model to initial state
    func reset() {
        state = .idle
        urlString = ""
        selectedVideoItem = nil
        analysisResult = nil
        videoThumbnail = nil
        showURLInput = false

        // Clean up downloaded file
        if let downloadedURL = downloadedFileURL {
            VideoDownloader.cleanup(localURL: downloadedURL)
            downloadedFileURL = nil
        }
    }
}
