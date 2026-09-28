# Contributing

Thanks for helping improve Video Smart Cut.

## Before opening an issue

- Search existing issues for the same problem or request.
- Include your macOS version, Mac architecture, `mlx-whisper` version, and FFmpeg version when reporting a bug.
- Do not attach private videos, transcripts, personal file paths, or logs that may contain them. A small synthetic test clip is safer.

## Pull requests

- Keep changes focused and explain the user-visible effect.
- Run `./scripts/build-app.sh` on an Apple silicon Mac before submitting Swift changes.
- Do not commit media files, model weights, app bundles, credentials, or personal machine paths.
- Update the README or privacy notes when behavior, dependencies, or data handling changes.

## Scope

Video Smart Cut is a local macOS menu-bar app. Contributions should preserve that workflow and should not add analytics, network uploads, or remote processing without an explicit privacy review.
