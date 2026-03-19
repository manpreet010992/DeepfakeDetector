import PhotosUI
import SwiftUI

/// Main content view of the app
struct ContentView: View {
    @StateObject private var viewModel = VideoAnalysisViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                Group {
                    switch viewModel.state {
                    case .idle:
                        HomeView(viewModel: viewModel)
                    case .loading:
                        LoadingView(message: "Preparing video...")
                    case .analyzing(let progress):
                        AnalysisProgressView(progress: progress)
                    case .completed:
                        if let result = viewModel.analysisResult {
                            ResultView(
                                result: result,
                                thumbnail: viewModel.videoThumbnail,
                                onReset: { viewModel.reset() }
                            )
                        }
                    case .error(let message):
                        ErrorView(
                            message: message,
                            onRetry: { viewModel.reset() }
                        )
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Home View

struct HomeView: View {
    @ObservedObject var viewModel: VideoAnalysisViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.accentGlow, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("DeepGuard")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("AI Video Detection")
                        .font(.subheadline)
                        .foregroundColor(.subtitleText)

                    Text("Upload a video or paste a URL to detect\nif it's AI-generated or authentic")
                        .font(.callout)
                        .foregroundColor(.subtitleText)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .padding(.top, 60)

                // Action buttons
                VStack(spacing: 16) {
                    // Upload Video Button
                    PhotosPicker(
                        selection: $viewModel.selectedVideoItem,
                        matching: .videos
                    ) {
                        ActionCard(
                            icon: "arrow.up.circle.fill",
                            title: "Upload Video",
                            subtitle: "Select from your photo library",
                            gradient: [.accentGlow, .blue]
                        )
                    }
                    .onChange(of: viewModel.selectedVideoItem) { newItem in
                        Task {
                            await viewModel.handleVideoSelection(newItem)
                        }
                    }

                    // URL Input Button
                    Button {
                        viewModel.showURLInput = true
                    } label: {
                        ActionCard(
                            icon: "link.circle.fill",
                            title: "Paste URL",
                            subtitle: "Analyze a video from a web link",
                            gradient: [.purple, .pink]
                        )
                    }
                }
                .padding(.horizontal, 24)

                // Info Section
                VStack(spacing: 16) {
                    Text("How It Works")
                        .font(.headline)
                        .foregroundColor(.white)

                    VStack(spacing: 12) {
                        InfoRow(
                            icon: "1.circle.fill",
                            text: "Upload a video or provide a URL"
                        )
                        InfoRow(
                            icon: "2.circle.fill",
                            text: "AI analyzes frames, motion & metadata"
                        )
                        InfoRow(
                            icon: "3.circle.fill",
                            text: "Get instant verdict with confidence score"
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Spacer(minLength: 40)
            }
        }
        .sheet(isPresented: $viewModel.showURLInput) {
            URLInputView(viewModel: viewModel)
        }
    }
}

// MARK: - Action Card

struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.subtitleText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.subtitleText)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: gradient.map { $0.opacity(0.3) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentGlow)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.subtitleText)

            Spacer()
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    let message: String

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .accentGlow))
                .scaleEffect(1.5)

            Text(message)
                .font(.headline)
                .foregroundColor(.subtitleText)
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.octagon.fill")
                .font(.system(size: 50))
                .foregroundColor(.verdictFake)

            Text("Something Went Wrong")
                .font(.title2.bold())
                .foregroundColor(.white)

            Text(message)
                .font(.body)
                .foregroundColor(.subtitleText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: onRetry) {
                Label("Try Again", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.accentGlow)
                    )
            }
        }
    }
}

#Preview {
    ContentView()
}
