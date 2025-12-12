#!/bin/sh
set -e

which clang-format
clang-format --version
find . -path ./build -prune -o -path ./.git -prune -o -regex '.*\.\(cpp\|hpp\|cc\|cxx\|h\|hh\|c\|hxx\)' -print0 | xargs -0 clang-format -i
