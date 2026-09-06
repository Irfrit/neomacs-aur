#!/usr/bin/env bash
set -euo pipefail

# Automated script to publish neomacs-bin to AUR
AUR_REPO="ssh://aur@aur.archlinux.org/neomacs-bin.git"
WORK_DIR="/tmp/neomacs-bin-aur-publish"
PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Updating .SRCINFO..."
(cd "$PACKAGE_DIR" && makepkg --printsrcinfo > .SRCINFO)

echo "==> Cloning AUR repository ($AUR_REPO)..."
rm -rf "$WORK_DIR"
git clone "$AUR_REPO" "$WORK_DIR"

echo "==> Copying package files..."
cp "$PACKAGE_DIR/PKGBUILD" "$PACKAGE_DIR/.SRCINFO" "$WORK_DIR/"

cd "$WORK_DIR"
git add PKGBUILD .SRCINFO
if ! git diff --cached --quiet; then
  PKGVER=$(grep -E '^pkgver=' PKGBUILD | cut -d= -f2)
  PKGREL=$(grep -E '^pkgrel=' PKGBUILD | cut -d= -f2)
  echo "==> Committing version ${PKGVER}-${PKGREL}..."
  git commit -m "neomacs-bin ${PKGVER}-${PKGREL}"
  echo "==> Pushing to AUR..."
  git push origin master || git push origin main
  echo "==> Published successfully to https://aur.archlinux.org/packages/neomacs-bin !"
else
  echo "==> AUR repository is already up to date."
fi
