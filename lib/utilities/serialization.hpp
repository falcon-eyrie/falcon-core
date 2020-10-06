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
#include <string>
#include "yaml-cpp/yaml.h"

namespace Serialization {

static const uint8_t VERSION = 1;

enum class Format { NONE = -1, FULL, COMPACT, HEADERONLY, STREAMHEADER };
// NONE: no packet header, no data header, no data
// FULL: packet header, data header and data
// HEADERONLY: packet header, data header, no data
// STREAMHEADER: packet header, no data header, no data
// COMPACT: data only

std::string format_to_string(Format fmt);
Format string_to_format(std::string s);

enum class Encoding { BINARY = 0, YAML, FLATBUFFER };

std::string encoding_to_string(Encoding fmt);
Encoding string_to_encoding(std::string s);

}  // namespace Serialization

namespace YAML {

template <> struct convert<Serialization::Format> {
  static Node encode(const Serialization::Format &rhs) {
    Node node;
    node = Serialization::format_to_string(rhs);
    return node;
  }

  static bool decode(const Node &node, Serialization::Format &rhs) {
    rhs = Serialization::string_to_format(node.as<std::string>());
    return true;
  }
};

template <> struct convert<Serialization::Encoding> {
  static Node encode(const Serialization::Encoding &rhs) {
    Node node;
    node = Serialization::encoding_to_string(rhs);
    return node;
  }

  static bool decode(const Node &node, Serialization::Encoding &rhs) {
    rhs = Serialization::string_to_encoding(node.as<std::string>());
    return true;
  }
};
}  // namespace YAML
