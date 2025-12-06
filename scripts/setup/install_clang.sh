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

echo "Moving to /opt/llvm-${VERSION} ..."
sudo mv llvm-extract "/opt/llvm-${VERSION}"

echo "Cleaning up $ARCHIVE..."
rm -f "$ARCHIVE"

echo "LLVM-${VERSION} installed successfully."
echo "----------------------------------"
