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

#include <algorithm>
#include <cctype>
#include <ostream>
#include <string>

#include "yaml-cpp/yaml.h"

#include "datatype_generated.h"
#include "idata.hpp"
#include "serialization.hpp"

namespace Serialization {

class Serializer {
  public:
    Serializer(Format fmt = Format::FULL, std::string description = "",
               std::string extension = "")
        : format_(fmt), description_(description), extension_(extension) {}

    virtual bool Serialize(std::ostream &stream, typename AnyType::Data *data,
                           uint16_t streamid, uint64_t packetid,
                           std::string processor, std::string port,
                           uint8_t slot) = 0;
    Format format() const;
    void set_format(Format fmt);

    YAML::Node DataDescription(const typename AnyType::Data &data) const;

    std::string description() const;
    std::string extension() const;

  protected:
    Format format_;
    std::string description_;
    std::string extension_;
};

class BinarySerializer : public Serializer {
  public:
    BinarySerializer(Format fmt = Format::FULL)
        : Serializer(fmt, "Compact binary format", "bin") {}

    bool Serialize(std::ostream &stream, typename AnyType::Data *data,
                   uint16_t streamid, uint64_t packetid, std::string processor,
                   std::string port, uint8_t slot);
};

class FlatBufferSerializer : public Serializer {
  public:
    FlatBufferSerializer(Format fmt = Format::FULL)
        : Serializer(fmt, "Flatbuffer format", "bin"), builder_(1024) {}

    bool Serialize(std::ostream &stream, typename AnyType::Data *data,
                   uint16_t streamid, uint64_t packetid, std::string processor,
                   std::string port, uint8_t slot);

  private:
    flatbuffers::FlatBufferBuilder builder_;
    flexbuffers::Builder flex_builder_;
};

class YAMLSerializer : public Serializer {
  public:
    YAMLSerializer(Format fmt = Format::FULL)
        : Serializer(fmt, "Human readable YAML format", "yaml") {}

    bool Serialize(std::ostream &stream, typename AnyType::Data *data,
                   uint16_t streamid, uint64_t packetid, std::string processor,
                   std::string port, uint8_t slot);
};

Serializer *serializer_from_string(std::string s,
                                   Serialization::Format fmt = Format::FULL);

Serializer *serializer(Serialization::Encoding enc,
                       Serialization::Format fmt = Format::FULL);

} // namespace Serialization
