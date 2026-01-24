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

#include "idata.hpp"
using namespace nsAnyType;

void Data::set_serial_number(uint64_t n) {
    serial_number_ = n;
}

uint64_t Data::serial_number() const {
    return serial_number_;
}

int64_t Data::ingestion_ns() const {
    return ingestion_ns_;
}

void Data::set_ingestion_ns() {
    ingestion_ns_ = std::chrono::duration_cast<std::chrono::nanoseconds>(
                        std::chrono::steady_clock::now().time_since_epoch())
                        .count();
}

void Data::forward_ingestion_ns(int64_t t) {
    ingestion_ns_ = t;
}

void Data::set_source_timestamp() {
    source_timestamp_ = Clock::now();
}

void Data::set_source_timestamp(TimePoint t) {
    source_timestamp_ = t;
}

TimePoint Data::source_timestamp() const {
    return source_timestamp_;
}

uint64_t Data::hardware_timestamp() const {
    return hardware_timestamp_;
}

void Data::set_hardware_timestamp(uint64_t t) {
    hardware_timestamp_ = t;
}

void Data::CloneTimestamps(const Data& data) {
    source_timestamp_ = data.source_timestamp_;
    hardware_timestamp_ = data.hardware_timestamp_;
}

void Data::SerializeBinary(std::ostream& stream, Serialization::Format format) const {
    if (format == Serialization::Format::FULL || format == Serialization::Format::HEADERONLY) {
        uint64_t t = std::chrono::duration_cast<std::chrono::microseconds>(
                         source_timestamp_.time_since_epoch())
                         .count();
        stream.write(reinterpret_cast<const char*>(&t), sizeof(t));
        stream.write(reinterpret_cast<const char*>(&hardware_timestamp_),
                     sizeof(hardware_timestamp_));
        stream.write(reinterpret_cast<const char*>(&serial_number_), sizeof(serial_number_));
    }
}

void Data::SerializeYAML(YAML::Node& node, Serialization::Format format) const {
    // FULL, HEADERONLY : add timestamps
    // otherwise: do nothing
    if (format == Serialization::Format::FULL || format == Serialization::Format::HEADERONLY) {
        node["source_ts"] =
            static_cast<uint64_t>(std::chrono::duration_cast<std::chrono::microseconds>(
                                      source_timestamp_.time_since_epoch())
                                      .count());
        node["hardware_ts"] = hardware_timestamp_;
        node["serial_number"] = serial_number_;
    }
}

void Data::YAMLDescription(YAML::Node& node, Serialization::Format format) const {
    // FULL, HEADERONLY : add timestamps
    // otherwise: do nothing
    if (format == Serialization::Format::FULL || format == Serialization::Format::HEADERONLY) {
        node.push_back("source_ts uint64 (1)");
        node.push_back("hardware_ts uint64 (1)");
        node.push_back("serial_number uint64 (1)");
    }
}

void Data::SerializeFlatBuffer(flexbuffers::Builder& flex_builder) {
    auto ts = static_cast<uint64_t>(
        std::chrono::duration_cast<std::chrono::microseconds>(source_timestamp().time_since_epoch())
            .count());
    flex_builder.UInt("source_ts", ts);
    flex_builder.UInt("hardware_ts", hardware_timestamp());
    flex_builder.UInt("serial_number", serial_number_);
}
