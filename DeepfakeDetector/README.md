# DeepGuard - AI Video Detector

An iOS app that detects whether a video is AI-generated or authentic using frame analysis, temporal coherence, and metadata inspection.

## Features

- **Upload Video**: Select a video from your photo library for analysis
- **URL Input**: Paste a direct video URL (MP4, MOV, AVI, WebM) to analyze
- **Multi-Factor Analysis**: Examines frame consistency, temporal coherence, compression artifacts, motion patterns, facial consistency, and audio-visual sync
- **Confidence Score**: Provides a percentage-based confidence in the verdict
- **Detailed Metrics**: Drill down into individual analysis metrics

## Architecture

- **SwiftUI** with MVVM pattern
- **AVFoundation** for video frame extraction and metadata
- **CoreImage** for face detection and image analysis
- iOS 16+ deployment target

## Project Structure

```
DeepfakeDetector/
├── App/
│   └── DeepfakeDetectorApp.swift          # App entry point
├── Models/
│   ├── VideoSource.swift                   # Video input source model
│   ├── AnalysisResult.swift               # Analysis result model
│   └── DetectionMetrics.swift             # Detection metrics model
├── ViewModels/
│   └── VideoAnalysisViewModel.swift       # Main view model
├── Views/
│   ├── ContentView.swift                  # Main view with home screen
│   ├── URLInputView.swift                 # URL input sheet
│   ├── AnalysisProgressView.swift         # Analysis progress display
│   └── ResultView.swift                   # Results display
├── Services/
│   ├── VideoAnalysisService.swift         # Core analysis engine
│   ├── FrameExtractor.swift               # AVFoundation frame extraction
│   └── VideoDownloader.swift              # Remote video downloader
├── Extensions/
│   └── Color+Extensions.swift             # App theme colors
└── Resources/
    └── Assets.xcassets/                   # App icons and colors
```

## How It Works

1. **Upload or paste URL** - Select a video from your photo library or enter a direct video URL
2. **Frame Extraction** - The app extracts frames at regular intervals using AVFoundation
3. **Multi-Factor Analysis** - Each frame is analyzed for:
   - Frame-to-frame consistency
   - Temporal coherence across the video
   - Metadata patterns
   - Compression artifact analysis
   - Motion pattern naturalness
   - Facial consistency (if faces detected)
   - Audio-visual synchronization (if audio present)
4. **Verdict** - Results are presented as Real, AI Generated, or Inconclusive with a confidence score

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.0+

## Getting Started

1. Open `DeepfakeDetector.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run (Cmd+R)

## Future Enhancements

- Core ML model integration for higher accuracy detection
- Support for live camera capture
- History of analyzed videos
- Share analysis reports
- Batch video analysis
