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

#include "serializer.hpp"

#include <utility>
#include "buildconstant.hpp"
#include "idata.hpp"

namespace Serialization {

Format Serializer::format() const {
    return format_;
}

void Serializer::set_format(Format fmt) {
    format_ = fmt;
}

std::string Serializer::description() const {
    return description_;
}

std::string Serializer::extension() const {
    return extension_;
}

YAML::Node Serialization::Serializer::DataDescription(const typename AnyType::Data& data) const {
    YAML::Node node;

    if (format_ == Serialization::Format::FULL || format_ == Serialization::Format::HEADERONLY ||
        format_ == Serialization::Format::STREAMHEADER) {
        node.push_back("stream uint16 (1)");
        node.push_back("packet uint64 (1)");
    }

    data.YAMLDescription(node, format_);

    return node;
}

bool Serialization::BinarySerializer::Serialize(std::ostream& stream, typename AnyType::Data* data,
                                                uint16_t streamid, uint64_t packetid,
                                                std::string processor, std::string port,
                                                uint8_t slot) {
    if (format_ == Serialization::Format::NONE) {
        return true;
    }

    if (format_ == Serialization::Format::COMPACT) {
        data->SerializeBinary(stream, format_);
    } else {
        stream.write(reinterpret_cast<const char*>(&streamid), sizeof(streamid));
        stream.write(reinterpret_cast<const char*>(&packetid), sizeof(packetid));
        data->SerializeBinary(stream, format_);
    }

    return true;
}

bool Serialization::FlatBufferSerializer::Serialize(std::ostream& stream,
                                                    typename AnyType::Data* data, uint16_t streamid,
                                                    uint64_t packetid, std::string processor,
                                                    std::string port, uint8_t slot) {
    if (format_ == Serialization::Format::NONE) {
        return true;
    }

    auto datasource = CreateDataSource(builder_, builder_.CreateString(processor),
                                       builder_.CreateString(port), slot, streamid);
    auto startMap = flex_builder_.StartMap();

    data->SerializeFlatBuffer(flex_builder_);
    flex_builder_.EndMap(startMap);
    flex_builder_.Finish();

    auto buffer = CreateRootMsg(builder_, builder_.CreateString(GIT_REVISION), packetid, datasource,
                                builder_.CreateString(data->datatype()),
                                builder_.CreateVector(flex_builder_.GetBuffer()));
    builder_.Finish(buffer);
    stream.write(reinterpret_cast<const char*>(builder_.GetBufferPointer()), builder_.GetSize());

    flex_builder_.Clear();
    builder_.Clear();
    return true;
}

bool Serialization::YAMLSerializer::Serialize(std::ostream& stream, typename AnyType::Data* data,
                                              uint16_t streamid, uint64_t packetid,
                                              std::string processor, std::string port,
                                              uint8_t slot) {
    if (format_ == Serialization::Format::NONE) {
        return true;
    }

    YAML::Emitter emit(stream);
    YAML::Node node;

    if (format_ == Serialization::Format::COMPACT) {
        data->SerializeYAML(node, format_);
        emit << YAML::BeginSeq;
        emit << YAML::Flow << node;
        emit << YAML::EndSeq;
        stream << '\n';
    } else {
        emit << YAML::BeginSeq << YAML::BeginMap;
        emit << YAML::Key << "stream" << YAML::Value << streamid;
        emit << YAML::Key << "packet" << YAML::Value << packetid;
        if (format_ != Serialization::Format::STREAMHEADER) {
            data->SerializeYAML(node, format_);
            emit << YAML::Key << "data" << YAML::Value << node;
        }
        emit << YAML::EndMap << YAML::EndSeq;
        stream << '\n';
    }

    return true;
}

Serializer* serializer_from_string(std::string s, Serialization::Format fmt) {
    return serializer(Serialization::string_to_encoding(std::move(s)), fmt);
}

Serializer* serializer(Serialization::Encoding enc, Serialization::Format fmt) {
    if (enc == Serialization::Encoding::BINARY) {
        return new Serialization::BinarySerializer(fmt);
    }
    if (enc == Serialization::Encoding::YAML) {
        return new Serialization::YAMLSerializer(fmt);
    }
    if (enc == Serialization::Encoding::FLATBUFFER) {
        return new Serialization::FlatBufferSerializer(fmt);
    }
    throw std::runtime_error("Unknown serializer.");
}
}  // namespace Serialization
