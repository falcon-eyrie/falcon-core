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

#include <memory>
#include <set>
#include <string>
#include <vector>

#include "streaminfo.hpp"

#include "t_idata.hpp"
#include "test_utilities.hpp"

#include "yaml-cpp/yaml.h"

class IPortOut;
class ISlotOut;
class IPortIn;
class ISlotIn;
class IProcessor;

class ISlotOut {
  friend class ISlotIn;
  template <typename DATATYPE> friend class SlotIn;
  friend class IPortOut;

 public:
  ISlotOut(IPortOut *parent, const SlotAddress &address)
      : parent_(parent), address_(address) {}
  const SlotAddress &address() const { return address_; }
  IPortOut *parent() { return parent_; }
  virtual IStreamInfo &streaminfo() = 0;

 protected:
  IPortOut *parent_;   // observing pointer
  SlotAddress address_;
};

class IPortOut {
  friend class IProcessor;

 public:
  IPortOut(IProcessor *parent, const PortAddress &address, PortOutPolicy policy)
      : parent_(parent), address_(address), policy_(policy) {}
  const PortAddress &address() const { return address_; }
  const PortOutPolicy &policy() const { return policy_; }
  IProcessor *parent() { return parent_; }

  virtual std::string datatype() const = 0;
  virtual ISlotOut *slot(std::size_t index) = 0;
  virtual SlotType number_of_slots() const = 0;

 protected:
  IProcessor *parent_;   // observing pointer
  PortAddress address_;

 private:
  std::string name_;
  PortOutPolicy policy_;
};

class ISlotIn {
  friend class IPortIn;
  template <typename DATATYPE> friend class PortIn;
  friend class ISlotOut;

 public:
  ISlotIn(IPortIn *parent, const SlotAddress &address, int64_t time_out = -1,
          bool cache = false)
      : cache_enabled_(cache), parent_(parent),
        address_(address) {}

  const SlotAddress &address() const { return address_; }
  IPortIn *parent() { return parent_; }
  void ReleaseData(){};

  void Connect(ISlotOut *upstream) {
    upstream_ = upstream;
  }

  const SlotAddress &upstream_address() {
    if (upstream_ == nullptr) {
      throw std::runtime_error(
          "Cannot get upstream address: slot is not connected.");
    }
    return upstream_->address();
  }

  const PortOutPolicy &upstream_policy() const {
    if (upstream_ == nullptr) {
      throw std::runtime_error(
          "Cannot get upstream policy: slot is not connected.");
    }
    return upstream_->parent()->policy();
  }

 protected:
  bool cache_enabled_;
  ISlotOut *upstream_ = nullptr;
  IPortIn *parent_;   // observing pointer
  SlotAddress address_;
};

class IPortIn {
  friend class IProcessor;

 public:
  IPortIn(IProcessor *parent, const PortAddress &address, PortInPolicy policy)
      : parent_(parent), address_(address), policy_(policy) {}

  const PortAddress &address() const { return address_; }
  const PortInPolicy &policy() const { return policy_; }
  IProcessor *parent() { return parent_; }

  virtual std::string datatype() const = 0;
  virtual SlotType number_of_slots() const = 0;
  virtual ISlotIn *slot(std::size_t index) = 0;

  std::string name() const {  return address_.port(); }

 protected:
  IProcessor *parent_;  // observing pointer
  PortAddress address_;

 private:
  PortInPolicy policy_;
};

