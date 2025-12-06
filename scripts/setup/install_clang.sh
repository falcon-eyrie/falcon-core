#!/usr/bin/env sh
set -e

# TODO(ben): Install the whole clang instead

VERSION=21.1.7
TMP_DIR=/tmp/llvm
BIN_DIR=/usr/bin

TOOLS="clang-format clang-tidy clang-query clang-apply-replacements run-clang-tidy"

echo "Setting up temporary directory..."
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

for TOOL in $TOOLS; do
    ARCHIVE="${TOOL}-$VERSION-linux-x64.tar.gz"
    URL="https://github.com/benfgit/clang-tools-binaries/releases/download/v$VERSION/$ARCHIVE"

    echo "Downloading $TOOL $VERSION..."
    curl -fsSL -o "$ARCHIVE" "$URL"

    echo "Extracting $TOOL..."
    tar -xf "$ARCHIVE"

    echo "Installing $TOOL to $BIN_DIR..."
    sudo mv "$TOOL" "$BIN_DIR/"
    sudo chmod +x "$BIN_DIR/$TOOL"

    echo "Cleaning up $ARCHIVE..."
    rm -f "$ARCHIVE"

    echo "✅ $TOOL installed successfully."
    echo "----------------------------------"
done

echo "All tools installed."
