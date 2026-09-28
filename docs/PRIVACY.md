# Privacy and Data Handling

Video Smart Cut is designed to process selected media locally.

## What the app does

- Reads the selected video through local command-line tools.
- Invokes the locally installed `mlx_whisper` executable to produce English word timestamps.
- Invokes local `ffprobe` and `ffmpeg` executables to inspect and render the video.
- Writes the finished MP4 to the destination folder chosen in the app.
- Uses a temporary working folder for transcript JSON and FFmpeg filter data, then removes that folder when processing finishes.

## Network and model downloads

The app source contains no telemetry client or direct network request. MLX Whisper may contact its model host to download the configured `mlx-community/whisper-large-v3-turbo` model the first time it is used, and may use its local model cache on later runs. This network behavior belongs to the separately installed MLX Whisper dependency. Model weights are not bundled here.

## Files and permissions

The app needs access to the input video and the chosen output folder. macOS may ask for access when files are outside locations already available to the app. Video Smart Cut does not intentionally modify the original input; it reserves a new output filename and writes a separate MP4.

## Before sharing diagnostic information

Logs and error messages can include full media or folder paths. Remove personal usernames, filenames, and other private information before posting them in an issue.
