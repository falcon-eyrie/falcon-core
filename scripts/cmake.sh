#!/bin/sh
set -e

if ! command -v cmake >/dev/null 2>&1; then
    echo "Error: CMake is not installed."
    echo "You can install it using: scripts/setup/install_cmake.sh"
    exit 1
fi

mkdir -p build && cd build

cmake .. \
  -DCMAKE_BUILD_TYPE=Profile \
  -DCMAKE_C_COMPILER=/usr/local/bin/clang \
  -DCMAKE_CXX_COMPILER=/usr/local/bin/clang++