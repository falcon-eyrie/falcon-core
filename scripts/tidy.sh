#!/bin/sh
set -e

which clang-format
clang-format --version

# This script gathers all relevant C and C++ files tracked by git
# (respecting .gitignore), excludes specific directories, and
# formats them using clang-tidy.

# Extensions of files to format
FILE_EXTS="*.c *.h *.cc *.cpp *.cxx *.c++ *.hh *.hpp *.hxx *.h++"

# Get files from git (respects .gitignore)
FILES=$(git ls-files --cached --others --exclude-standard $FILE_EXTS)

# Directories to ignore even if they are tracked by git
MANUAL_EXCLUDE="
falcon_gui
"

# Filter out manual excludes
for dir in $MANUAL_EXCLUDE; do
    FILES=$(echo "$FILES" | grep -v "^$dir/")
done

if [ -z "$FILES" ]; then
    echo "No matching files found."
    exit 0
fi

echo "$FILES" | xargs run-clang-tidy -p build -j "$(nproc 2>/dev/null)"
