#!/usr/bin/env bash
set -e

VERSION=21.1.5
TMP_DIR=/tmp/llvm
ARCHIVE=clang-format-$VERSION-linux-x64.tar.gz
URL="https://github.com/benfgit/clang-tools-binaries/releases/download/v$VERSION/$ARCHIVE"

echo "Setting up temporary directory..."
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

echo "Downloading clang-format $VERSION..."
wget -q -O "$ARCHIVE" "$URL"

echo "Extracting archive..."
tar -xf "$ARCHIVE"

echo "Installing clang-format to /usr/local/bin..."
sudo mv clang-format /usr/local/bin/
sudo chmod +x /usr/local/bin/clang-format

echo "Cleaning up..."
rm -f "$ARCHIVE"

echo "Installation complete."
echo "----------------------------------"
clang-format --version
