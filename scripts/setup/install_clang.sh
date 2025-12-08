#!/bin/sh
set -e

VERSION=21.1.7

cd /tmp

ARCHIVE="clang-${VERSION}-minimal-linux-x64.tar.gz"
URL="https://github.com/benfgit/clang-tools-binaries/releases/download/v${VERSION}/${ARCHIVE}"

echo "Downloading minimal LLVM $VERSION..."
curl --fail --show-error --location --output "$ARCHIVE" "$URL"

mkdir -p llvm-minimal
tar -xzf "$ARCHIVE" -C llvm-minimal

echo "Extracted minimal LLVM archive into llvm-minimal/"

echo "Installing to /usr/local/llvm-${VERSION} ..."
sudo rm -rf "/usr/local/llvm-${VERSION}"
sudo mv llvm-minimal "/usr/local/llvm-${VERSION}-min"

echo "Creating minimal symlinks in /usr/local/bin ..."
sudo ln -sf /usr/local/llvm-${VERSION}-min/* /usr/local/bin/

echo "Cleaning up $ARCHIVE..."
rm -f "$ARCHIVE"

echo "Minimal LLVM-${VERSION} installed successfully."
