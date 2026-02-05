#!/bin/sh
set -e

which clang-format
clang-format --version

# This script gathers all relevant C and C++ files tracked by git
# (respecting .gitignore), excludes specific directories, and
# formats them using clang-format.

# Extensions of files to format
FILE_EXTS="*.[ch] *.cpp *.hpp *.cc *.cxx *.hh *.hxx"


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

echo "$FILES" | xargs clang-format -i
   