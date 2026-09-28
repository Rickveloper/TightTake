# TightTake

![TightTake — local-first silence editing for macOS](assets/repository-banner.png)

TightTake is the open-source project for a menu-bar macOS silence cutter. The included app currently appears in macOS as **Video Smart Cut**. It trims long pauses while keeping a little breathing room around speech and creates a new MP4 instead of modifying the input.

The app runs on Apple silicon Macs. It uses [MLX Whisper](https://github.com/ml-explore/mlx-examples/tree/main/whisper) for local word timestamps and FFmpeg for the final render.

## What it does

- Lives in the macOS menu bar; drag in a video or choose one from a file picker.
- Transcribes English speech locally, then keeps speech sections and configurable pauses.
- Leaves 0.20 seconds before and 0.30 seconds after each recognized word to avoid abrupt cuts.
- Renders a new MP4 with FFmpeg; Apple VideoToolbox hardware encoding is optional.
- Lets you choose an output folder and filename. Existing files are preserved; a numbered name is used instead.
- Shows transcription, analysis, and render progress.

Supported input extensions: `.mp4`, `.mov`, `.m4v`, and `.mkv`.

## Requirements

- Apple silicon Mac (arm64) running macOS 14 or later.
- Xcode Command Line Tools, including `swiftc`.
- Homebrew FFmpeg (`ffmpeg` and `ffprobe`).
- Python and `pipx` to install `mlx-whisper`.
- Internet access the first time MLX Whisper fetches the configured model. The model is not included in this repository.

Install the command-line dependencies:

```sh
brew install ffmpeg pipx
pipx install mlx-whisper
```

The app looks for `mlx_whisper` in `~/.local/bin`, `/opt/homebrew/bin`, and `/usr/local/bin`, and for FFmpeg tools in the common Homebrew and system locations. If your tools are installed elsewhere, make them available in one of those locations before launching the app.

## Build and run

```sh
git clone https://github.com/Rickveloper/tighttake.git
cd tighttake
./scripts/build-app.sh
open "build/Video Smart Cut.app"
```

The build script compiles the Swift source into a standard `.app` bundle and applies an ad-hoc signature for local development. It does not produce an Apple Developer ID signature or notarization. There is no prebuilt installer in this source repository.

To regenerate the original project artwork and app icon on a Mac, run `./scripts/package-assets.sh`.

## Privacy

Video Smart Cut has no in-app telemetry or network client. The app passes the selected video path to the locally installed `mlx_whisper`, `ffprobe`, and `ffmpeg` processes. Transcription and rendering are performed on the Mac, and the app does not upload the video or its transcript.

On first use, MLX Whisper may download model files from its configured model host and cache them on the Mac. That download is performed by the separately installed MLX Whisper tool, not by an upload feature in Video Smart Cut. Review the dependency and model terms before use. See [Privacy and Data Handling](docs/PRIVACY.md) for details.

## Open-source status

This project is distributed under the MIT License. Third-party tools and model files are separate dependencies and retain their own licenses and terms. See [Security](docs/SECURITY.md) to report a vulnerability and [Contributing](CONTRIBUTING.md) for project guidelines.

## Current validation

The included Swift source has been type-checked on Apple silicon with the macOS SDK. A clean build can be produced with the script above. This initial public source publication has not been independently tested on a clean Mac, and the app is not notarized; review the source and dependency requirements before using it with important footage.
