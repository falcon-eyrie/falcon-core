// ---------------------------------------------------------------------
// This file is part of falcon-core.
//
// Copyright (C) 2015, 2016, 2017 Neuro-Electronics Research Flanders
//
// Falcon-server is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Falcon-server is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with falcon-core. If not, see <http://www.gnu.org/licenses/>.
// ---------------------------------------------------------------------

#pragma once
#include <vector>
// modified from https://stackoverflow.com/a/53365539
// We haven't checked which filesystem to include yet
#ifndef INCLUDE_STD_FILESYSTEM_EXPERIMENTAL

// Check for feature test macro for <filesystem>
#if defined(__cpp_lib_filesystem)
#define INCLUDE_STD_FILESYSTEM_EXPERIMENTAL 0

// Check for feature test macro for <experimental/filesystem>
#elif defined(__cpp_lib_experimental_filesystem)
#define INCLUDE_STD_FILESYSTEM_EXPERIMENTAL 1

// We can't check if headers exist...
// Let's assume experimental to be safe
#elif !defined(__has_include)
#define INCLUDE_STD_FILESYSTEM_EXPERIMENTAL 1

// Check if the header "<filesystem>" exists
#elif __has_include(<filesystem>)

// If we're compiling on Visual Studio and are not compiling with C++17, we need
// to use experimental
#ifdef _MSC_VER

// Check and include header that defines "_HAS_CXX17"
#if __has_include(<yvals_core.h>)
#include <yvals_core.h>

// Check for enabled C++17 support
#if defined(_HAS_CXX17) && _HAS_CXX17
// We're using C++17, so let's use the normal version
#define INCLUDE_STD_FILESYSTEM_EXPERIMENTAL 0
#endif
#endif

// If the marco isn't defined yet, that means any of the other VS specific
// checks failed, so we need to use experimental
#ifndef INCLUDE_STD_FILESYSTEM_EXPERIMENTAL
#define INCLUDE_STD_FILESYSTEM_EXPERIMENTAL 1
#endif

// Not on Visual Studio. Let's use the normal version
#else // #ifdef _MSC_VER
#define INCLUDE_STD_FILESYSTEM_EXPERIMENTAL 0
#endif

// Check if the header "<filesystem>" exists
#elif __has_include(<experimental/filesystem>)
#define INCLUDE_STD_FILESYSTEM_EXPERIMENTAL 1

// Fail if neither header is available with a nice error message
#else
#error Could not find system header "<filesystem>" or
"<experimental/filesystem>"
#endif

// We priously determined that we need the exprimental version
#if INCLUDE_STD_FILESYSTEM_EXPERIMENTAL
// Include it
#include <experimental/filesystem>

// We need the alias from std::experimental::filesystem to std::filesystem
namespace fs = std::experimental::filesystem;

// We have a decent compiler and can use the normal version
#else
// Include it
#include <filesystem>
namespace fs = std::filesystem;
#endif

#endif // #ifndef INCLUDE_STD_FILESYSTEM_EXPERIMENTAL

#include <string>

/**
 * LINUX specific - expand $HOME or ~ to HOME environment variable
 *
 *@param x Path containing home to expand
 **/
std::string expand_home(const std::string &x);
/**
 * Check if the path is already existing and is a directory - create one if
 *asked
 *
 *@param x Path of directory to be check
 *@param exists directory at the end of this method should exist
 *@param create create the directory if not existing while expected to.
 *@return absolute path if a valid directory
 **/
fs::path parse_directory(const std::string &x, bool exists = true,
                         bool create = false);
/**
 * Check if the path is already existing and is a file
 *
 *@param x Path of directory to be check
 *@param exists expected of already existing or not
 *@return absolute path if a valid file
 **/
fs::path parse_file(const std::string &x, bool exists = false);

/**
 * Get the list of all files in given directory and its sub directories.
 *
 *@param dirPath Path of directory to be traversed
 *@return vector containing paths of all the files in given directory and its
 *sub directories
 **/
std::vector<std::string> getAllFilesInDir(const std::string &dirPath);
