#!/bin/sh
set -e

VERSION=4.1.2
TMP_DIR=/tmp
INSTALLER=cmake-$VERSION-linux-x86_64.sh
URL="https://github.com/Kitware/CMake/releases/download/v$VERSION/$INSTALLER"

echo "Downloading CMake $VERSION..."
curl --fail --silent --show-error --location -o "$TMP_DIR/$INSTALLER" "$URL"

echo "Making installer executable..."
chmod +x "$TMP_DIR/$INSTALLER"

echo "Installing CMake system-wide..."
sudo "$TMP_DIR/$INSTALLER" --prefix=/usr/local --skip-license

echo "Cleaning up..."
rm -f "$TMP_DIR/$INSTALLER"

echo "Done! Installed version:"
which cmake
cmake --version
