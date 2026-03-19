import Foundation

/// Represents the source of a video to be analyzed
enum VideoSource {
    case photoLibrary(URL)
    case url(URL)

    var url: URL {
        switch self {
        case .photoLibrary(let url):
            return url
        case .url(let url):
            return url
        }
    }

    var displayName: String {
        switch self {
        case .photoLibrary:
            return "Uploaded Video"
        case .url(let url):
            return url.lastPathComponent.isEmpty ? url.absoluteString : url.lastPathComponent
        }
    }

    var isRemote: Bool {
        switch self {
        case .photoLibrary:
            return false
        case .url:
            return true
        }
    }
}
