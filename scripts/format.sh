#!/usr/bin/env bash
set -e

if ! command -v clang-format >/dev/null 2>&1; then
    echo "Error: clang-format is not installed."
    echo "You can install it using: scripts/setup/install_clang_format.sh"
    exit 1
fi

clang-format --version
find . -path ./build -prune -o -path ./.git -prune -o -regex '.*\.\(cpp\|hpp\|cc\|cxx\|h\|hh\|c\|hxx\)' -print0 | xargs -0 clang-format -i
