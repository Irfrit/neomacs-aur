#!/usr/bin/env bash
set -euo pipefail

# Auto-update script for neomacs-bin AUR package
# Usage: ./update-aur.sh [VERSION]
# Example: ./update-aur.sh 0.0.14

REPO="eval-exec/neomacs"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKGBUILD_FILE="${SCRIPT_DIR}/PKGBUILD"

if [ -n "${1:-}" ]; then
  NEW_VER="${1#v}"
else
  echo "Fetching latest release tag from GitHub..."
  TAG=$(curl -sL "https://api.github.com/repos/${REPO}/releases/latest" | jq -r '.tag_name // empty' 2>/dev/null || curl -sL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  if [ -z "$TAG" ] || [ "$TAG" = "null" ]; then
    echo "Error: Could not fetch latest release tag." >&2
    exit 1
  fi
  NEW_VER="${TAG#v}"
fi

echo "Target version: ${NEW_VER}"

TARBALL_URL="https://github.com/${REPO}/releases/download/v${NEW_VER}/neomacs-${NEW_VER}-x86_64-unknown-linux-gnu.tar.gz"

echo "Downloading release tarball to calculate sha256 checksum..."
TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"' EXIT

if ! curl -sL --fail "$TARBALL_URL" -o "$TEMP_FILE"; then
  echo "Error: Failed to download release tarball from $TARBALL_URL" >&2
  exit 1
fi

TARBALL_SHA256=$(sha256sum "$TEMP_FILE" | awk '{print $1}')
echo "New sha256: ${TARBALL_SHA256}"

# Update PKGBUILD pkgver, pkgrel, and tarball sha256
sed -i -E "s/^pkgver=.*/pkgver=${NEW_VER}/" "$PKGBUILD_FILE"
sed -i -E "s/^pkgrel=.*/pkgrel=1/" "$PKGBUILD_FILE"
sed -i -E "0,/sha256sums=\('[a-f0-9]{64}'/s//sha256sums=\('${TARBALL_SHA256}'/" "$PKGBUILD_FILE"

echo "Regenerating .SRCINFO..."
(cd "$SCRIPT_DIR" && makepkg --printsrcinfo > .SRCINFO)

echo "Update complete for version ${NEW_VER}!"
git -C "$SCRIPT_DIR" status || true
