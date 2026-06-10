#!/bin/sh
set -e

# libpython3.11 needed by lldb-dap
# Check if libpython3.11 is missing from current repos
if ! apt-cache show libpython3.11 >/dev/null 2>&1; then
    echo "Adding deadsnakes PPA..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq software-properties-common > /dev/null
    sudo add-apt-repository -y ppa:deadsnakes/ppa > /dev/null
else
    echo "libpython3.11 found."
fi
sudo apt-get update -qq
sudo apt-get install -y -qq libpython3.11 > /dev/null


VERSION=22.1.7

cd /usr/local

ARCHIVE="LLVM-${VERSION}.tar.xz"
URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-${VERSION}/LLVM-${VERSION}-Linux-X64.tar.xz"

echo "Downloading LLVM $VERSION..."
sudo curl -fsSL -o "$ARCHIVE" "$URL"

echo "Extracting LLVM archive into llvm-${VERSION}/..."

sudo rm -rf "llvm-${VERSION}"
sudo mkdir -p "llvm-${VERSION}"

# Use `pixz` for parallel decompression
# It works 2x faster on Github CI, compared to regular `xz`
sudo tar --use-compress-program=pixz -xf "$ARCHIVE" \
    -C "llvm-${VERSION}" --strip-components=1

echo "Extracted LLVM archive into llvm-${VERSION}/"

echo "Creating symlinks in /usr/local/bin ..."
sudo ln -sf /usr/local/llvm-${VERSION}/bin/* /usr/local/bin/

echo "Cleaning up $ARCHIVE..."
sudo rm -f "$ARCHIVE"

echo "LLVM-${VERSION} installed successfully."
lldb-dap --version
