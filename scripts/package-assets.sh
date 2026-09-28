#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ASSET_DIR="$PROJECT_ROOT/assets"
ICONSET_DIR="$ASSET_DIR/AppIcon.iconset"

for tool in swift sips iconutil; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing artwork tool: $tool." >&2
    exit 1
  fi
done

swift "$SCRIPT_DIR/render-artwork.swift" "$ASSET_DIR"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

make_icon() {
  local size="$1"
  local filename="$2"
  sips -s format png -z "$size" "$size" "$ASSET_DIR/app-icon.png" --out "$ICONSET_DIR/$filename" >/dev/null
}

make_icon 16 icon_16x16.png
make_icon 32 icon_16x16@2x.png
make_icon 32 icon_32x32.png
make_icon 64 icon_32x32@2x.png
make_icon 128 icon_128x128.png
make_icon 256 icon_128x128@2x.png
make_icon 256 icon_256x256.png
make_icon 512 icon_256x256@2x.png
make_icon 512 icon_512x512.png
cp "$ASSET_DIR/app-icon.png" "$ICONSET_DIR/icon_512x512@2x.png"

iconutil -c icns -o "$ASSET_DIR/AppIcon.icns" "$ICONSET_DIR"
printf 'Artwork and macOS app icon regenerated in %s\n' "$ASSET_DIR"
