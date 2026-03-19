import SwiftUI

/// View for entering a video URL
struct URLInputView: View {
    @ObservedObject var viewModel: VideoAnalysisViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isURLFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    // Icon
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.top, 40)

                    Text("Enter Video URL")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text("Paste a direct link to a video file\n(MP4, MOV, AVI, or WebM)")
                        .font(.subheadline)
                        .foregroundColor(.subtitleText)
                        .multilineTextAlignment(.center)

                    // URL Input Field
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.subtitleText)

                            TextField("https://example.com/video.mp4", text: $viewModel.urlString)
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                                .keyboardType(.URL)
                                .textContentType(.URL)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .focused($isURLFieldFocused)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            isURLFieldFocused ? Color.accentGlow : Color.subtitleText.opacity(0.3),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .padding(.horizontal, 24)

                    // Analyze Button
                    Button {
                        dismiss()
                        Task {
                            await viewModel.analyzeFromURL()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "waveform.and.magnifyingglass")
                            Text("Analyze Video")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                    .padding(.horizontal, 24)
                    .disabled(viewModel.urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(
                        viewModel.urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? 0.5 : 1.0
                    )

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.accentGlow)
                }
            }
        }
        .onAppear {
            isURLFieldFocused = true
        }
    }
}

#Preview {
    URLInputView(viewModel: VideoAnalysisViewModel())
}
