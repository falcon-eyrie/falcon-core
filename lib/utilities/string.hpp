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

/*
 Utilities to manipulate, create and check string data and other containers with
 strings.
 */

#pragma once

#include <cstdint>
#include <iomanip>
#include <map>
#include <sstream>
#include <string>
#include <vector>

bool path_exists(const std::string &name);

std::vector<std::string> &split(const std::string &s, char delim,
                                std::vector<std::string> &elems);

std::vector<std::string> split(const std::string &s, char delim);

template <typename T>
std::string join(const std::vector<T> &s, std::string delim = ",");

std::string
resolve_server_path(std::string p,
                    const std::map<std::string, std::string> &contexts,
                    std::string default_context = "");

template <typename T> std::string to_string_n(const T a_value, const int n = 1);

template <typename T> T from_string(std::string s);

// removes the appended (complete or incomplete) filename from the path
// and returns the path to the folder;
// returned path ends with '/'
std::string extract_path_to_folder(std::string path_to_file);

//
std::string complete_path(std::string file_path, std::string processor_name,
                          std::string extension);

template <typename T> inline std::string get_type_string() { return "unknown"; }
template <> inline std::string get_type_string<bool>() { return "bool"; }
template <> inline std::string get_type_string<double>() { return "float64"; }
template <> inline std::string get_type_string<float>() { return "float32"; }
template <> inline std::string get_type_string<int8_t>() { return "int8"; }
template <> inline std::string get_type_string<uint8_t>() { return "uint8"; }
template <> inline std::string get_type_string<int16_t>() { return "int16"; }
template <> inline std::string get_type_string<uint16_t>() { return "uint16"; }
template <> inline std::string get_type_string<int32_t>() { return "int32"; }
template <> inline std::string get_type_string<uint32_t>() { return "uint32"; }
template <> inline std::string get_type_string<int64_t>() { return "int64"; }
template <> inline std::string get_type_string<uint64_t>() { return "uint64"; }
template <> inline std::string get_type_string<char>() { return "char"; }

#include "string.ipp"
