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

#include <algorithm>
#include <stdexcept>

#include "serialization.hpp"

namespace Serialization {

std::string format_to_string(Format fmt) {
    std::string s;
#define MATCH(p)                                                               \
    case (Serialization::Format::p):                                           \
        s = #p;                                                                \
        break;
    switch (fmt) {
        MATCH(NONE)
        MATCH(FULL);
        MATCH(COMPACT);
        MATCH(HEADERONLY);
        MATCH(STREAMHEADER);
    }
#undef MATCH
    return s;
}

Format string_to_format(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(), (int (*)(int))std::toupper);
#define MATCH(p)                                                               \
    if (s == #p) {                                                             \
        return Serialization::Format::p;                                       \
    }
    MATCH(NONE)
    MATCH(FULL);
    MATCH(COMPACT);
    MATCH(HEADERONLY);
    MATCH(STREAMHEADER);
    throw std::runtime_error("Invalid Serialization::Format value.");
#undef MATCH
}

std::string encoding_to_string(Encoding enc) {
    std::string s;
#define MATCH(p)                                                               \
    case (Serialization::Encoding::p):                                         \
        s = #p;                                                                \
        break;
    switch (enc) {
        MATCH(BINARY)
        MATCH(YAML)
        MATCH(FLATBUFFER);
    }
#undef MATCH
    return s;
}

Encoding string_to_encoding(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(), (int (*)(int))std::toupper);
#define MATCH(p)                                                               \
    if (s == #p) {                                                             \
        return Serialization::Encoding::p;                                     \
    }
    MATCH(BINARY)
    MATCH(YAML)
    MATCH(FLATBUFFER);
    throw std::runtime_error("Invalid Serialization::Encoding value.");
#undef MATCH
}

} // namespace Serialization
