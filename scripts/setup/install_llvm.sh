#!/bin/sh
set -e

VERSION=21.1.7

cd /tmp

ARCHIVE="LLVM-${VERSION}.tar.xz"
URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-${VERSION}/LLVM-${VERSION}-Linux-X64.tar.xz"

echo "Downloading LLVM $VERSION..."
curl -fsSL -o "$ARCHIVE" "$URL"

mkdir -p llvm-extract
tar -xf "$ARCHIVE" -C llvm-extract --strip-components=1

echo "Extracted LLVM archive into llvm-extract/"

echo "Installing to /usr/local/llvm-${VERSION} ..."
sudo rm -rf "/usr/local/llvm-${VERSION}"
sudo mv llvm-extract "/usr/local/llvm-${VERSION}"

echo "Creating symlinks in /usr/local/bin ..."
sudo ln -sf /usr/local/llvm-${VERSION}/bin/* /usr/local/bin/

echo "Cleaning up $ARCHIVE..."
rm -f "$ARCHIVE"

echo "LLVM-${VERSION} installed successfully."
clang --version
