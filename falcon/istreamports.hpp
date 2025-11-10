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

#include "connections.hpp"
#include "idata.hpp"
#include "portpolicy.hpp"
#include "streaminfo.hpp"

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
        : ring_batch_(1), buffer_size_(-1), parent_(parent), address_(address) {
    }

    virtual ~ISlotOut() {}

    const SlotAddress &address() const { return address_; }
    IPortOut *parent() { return parent_; }
    bool connected() const { return downstream_slots_.size() > 0; }
    int nconnected() const { return downstream_slots_.size(); }
    virtual IStreamInfo &streaminfo() = 0;
    int buffer_size() const { return buffer_size_; }

  protected:
    // called by IPortOut
    void Connect(ISlotIn *downstream);

    // called by SlotIn
    int64_t WaitFor(int64_t sequence) const {
        return barrier_->WaitFor(sequence);
    }
    int64_t WaitFor(int64_t sequence, int64_t time_out) const {
        return barrier_->WaitFor(sequence, time_out);
    }

    virtual typename AnyType::Data *DataAt(int64_t sequence) const = 0;
    std::vector<RingSequence *> gating_sequences();

  protected:
    RingBatch ring_batch_;
    bool has_publishable_data_ = false;

    // need to go through base class, since we don't know
    // the exact datatype of downstream slots
    std::set<ISlotIn *> downstream_slots_;

    std::unique_ptr<RingBarrier> barrier_ = nullptr;
    int buffer_size_;

    IPortOut *parent_; // observing pointer
    SlotAddress address_;
};

class IPortOut {
    friend class ProcessorEngine;
    friend class IProcessor;

  public:
    IPortOut(IProcessor *parent, const PortAddress &address,
             PortOutPolicy policy)
        : parent_(parent), address_(address), policy_(policy) {}

    virtual ~IPortOut() {}
    const PortAddress &address() const { return address_; }
    const PortOutPolicy &policy() const { return policy_; }
    IProcessor *parent() { return parent_; }

    virtual std::string datatype() const = 0;
    virtual ISlotOut *slot(std::size_t index) = 0;
    virtual SlotType number_of_slots() const = 0;

    YAML::Node ExportYAML() const;
    std::string name() const { return address_.port(); }

  protected:
    // called by StreamOutConnector
    virtual void Connect(int slot, ISlotIn *downstream) = 0;
    virtual int ReserveSlot(int slot) = 0;
    virtual void CreateRingBuffers() = 0;
    virtual void UnlockSlots() = 0;
    virtual void PrepareProcessing() = 0;
    virtual void NewSlot(int n = 1) = 0;

    void set_buffer_size(int sz) { policy_.set_buffer_size(sz); }

    IProcessor *parent_; // observing pointer
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
    ISlotIn(IPortIn *parent, const SlotAddress &address, bool cache = false)
        : cache_enabled_(cache), parent_(parent), address_(address) {}

    virtual ~ISlotIn() {}

    const SlotAddress &address() const { return address_; }
    IPortIn *parent() { return parent_; }

    void NegotiateUpstream();
    bool connected() const { return upstream_ != nullptr; }
    void ReleaseData();

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

    virtual void Validate() = 0;

  protected:
    // called by upstream ISlotOut
    RingSequence *sequence() { return &sequence_; }

    // called by IPortIn
    void Connect(ISlotOut *upstream);
    void PrepareProcessing();

  protected:
    bool cache_enabled_;
    int64_t ncached_ = 0;
    int64_t nretrieved_ = 0;

    typename AnyType::Data *cache_ = nullptr;
    // access to upstream slot needs to go through base pointer
    // (since we don't know the exact datatype)
    ISlotOut *upstream_ = nullptr;

    RingSequence sequence_; // the input slot's read cursor into the buffer
    IPortIn *parent_;       // observing pointer
    SlotAddress address_;
};

class IPortIn {
    friend class ProcessorEngine;
    friend class IProcessor;

  public:
    IPortIn(IProcessor *parent, const PortAddress &address, PortInPolicy policy)
        : parent_(parent), address_(address), policy_(policy) {}

    virtual ~IPortIn() {}

    const PortAddress &address() const { return address_; }
    const PortInPolicy &policy() const { return policy_; }
    IProcessor *parent() { return parent_; }

    virtual std::string datatype() const = 0;
    virtual SlotType number_of_slots() const = 0;
    virtual ISlotIn *slot(std::size_t index) = 0;

    YAML::Node ExportYAML() const;
    std::string name() const { return address_.port(); }

  protected:
    // called by StreamInConnector
    virtual void Connect(int slot, ISlotOut *upstream) = 0;
    virtual int ReserveSlot(int slot) = 0;
    // called by ...
    virtual void PrepareProcessing() = 0;
    virtual void UnlockSlots() = 0;

    IProcessor *parent_; // observing pointer
    PortAddress address_;

  private:
    std::string name_;
    PortInPolicy policy_;
};
