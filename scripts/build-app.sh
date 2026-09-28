#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_BUNDLE="$PROJECT_ROOT/build/Video Smart Cut.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DEPLOYMENT_TARGET="${MACOS_DEPLOYMENT_TARGET:-14.0}"

if [[ "$(uname -m)" != "arm64" && "$(sysctl -n hw.optional.arm64 2>/dev/null || echo 0)" != "1" ]]; then
  echo "Video Smart Cut currently targets Apple silicon (arm64)." >&2
  exit 1
fi

for tool in swiftc xcrun plutil codesign; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing build tool: $tool. Install Xcode Command Line Tools." >&2
    exit 1
  fi
done

SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources" "$PROJECT_ROOT/build/ModuleCache"
cp "$PROJECT_ROOT/Info.plist" "$CONTENTS/Info.plist"
cp "$PROJECT_ROOT/assets/AppIcon.icns" "$CONTENTS/Resources/AppIcon.icns"

swiftc \
  -O \
  -target "arm64-apple-macosx${MACOS_DEPLOYMENT_TARGET}" \
  -sdk "$SDK_PATH" \
  -module-cache-path "$PROJECT_ROOT/build/ModuleCache" \
  -framework Cocoa \
  "$PROJECT_ROOT/source/VideoSmartCut.swift" \
  -o "$CONTENTS/MacOS/VideoSmartCut"

plutil -lint "$CONTENTS/Info.plist"
codesign --force --deep --sign - --timestamp=none "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE"

printf 'Built and ad-hoc signed: %s\n' "$APP_BUNDLE"
printf 'This local build is not Developer ID signed or notarized.\n'
