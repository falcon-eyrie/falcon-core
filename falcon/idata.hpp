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

#include <cassert>
#include <chrono>
#include <deque>
#include <limits>
#include <memory>
#include <string>

#include "ringbuffer.hpp"

#include "logging/log.hpp"
#include "utilities/time.hpp"
#include "serialization.hpp"
#include "yaml-cpp/yaml.h"
#include "datatype_generated.h"
#include "flatbuffers/flatbuffers.h"
#include "flatbuffers/flexbuffers.h"

namespace nsAnyType {

struct Parameters {};

class Data {
 public:
  Data() : hardware_timestamp_(0), serial_number_(0) {}
  virtual ~Data() {}

  virtual void ClearData() {}

  void Initialize(const Parameters &parameters) {}

  bool eos() const;
  void set_eos(bool value = true);
  void clear_eos();

  void set_serial_number(uint64_t n);
  uint64_t serial_number() const;

  void set_source_timestamp();
  void set_source_timestamp(TimePoint t);

  TimePoint source_timestamp() const;

  template <typename DURATION = std::chrono::microseconds>
  DURATION time_passed() const {
    return std::chrono::duration_cast<DURATION>(Clock::now() -
                                                source_timestamp_);
  }

  template <typename DURATION = std::chrono::microseconds>
  DURATION time_since(TimePoint reference) const {
    return std::chrono::duration_cast<DURATION>(Clock::now() - reference);
  }

  uint64_t hardware_timestamp() const;
  void set_hardware_timestamp(uint64_t t);

  void CloneTimestamps(const Data &data);

  virtual void SerializeBinary(std::ostream &stream,
                               Serialization::Format format) const;

  virtual void SerializeYAML(YAML::Node &node,
                             Serialization::Format format) const;

  virtual void YAMLDescription(YAML::Node &node,
                               Serialization::Format format) const;

  virtual void SerializeFlatBuffer(flexbuffers::Builder& flex_builder);


 protected:
  TimePoint source_timestamp_;
  uint64_t hardware_timestamp_;   // e.g. from Neuralynx
  uint64_t serial_number_;
  bool end_of_stream_ = false;

};

class Capabilities {
 public:
  void Validate(const Data & prototype) const {}
};

}   // namespace nsAnyType

class AnyType {
 public:
  static const std::string datatype() { return "any"; }
  static const std::string dataname() { return "data"; }

  using Parameters = nsAnyType::Parameters;
  using Capabilities = nsAnyType::Capabilities;
  using Data = nsAnyType::Data;
};
