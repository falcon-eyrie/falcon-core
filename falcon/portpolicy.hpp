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

#include "ringbuffer.hpp"
#include "utilities/math_numeric.hpp"

typedef uint16_t SlotType;
typedef Range<SlotType> SlotRange;

class PortPolicy {
   public:
    PortPolicy(SlotRange slot_number_range = SlotRange(1))
        : slot_number_range_(slot_number_range) {}

    const SlotRange& slot_number_range() const { return slot_number_range_; }
    SlotType min_slot_number() const { return slot_number_range_.lower(); }
    SlotType max_slot_number() const { return slot_number_range_.upper(); }

    bool isdynamic() const { return max_slot_number() > min_slot_number(); }

   protected:
    SlotRange slot_number_range_;
};

class PortInPolicy : public PortPolicy {
   public:
    PortInPolicy(SlotRange slot_number_range = SlotRange(1), bool cache = false)
        : PortPolicy(slot_number_range), cache_enabled_(cache) {}

    bool cache_enabled() const { return cache_enabled_; }

   protected:
    bool cache_enabled_;  // input slot only
};

class PortOutPolicy : public PortPolicy {
   public:
    PortOutPolicy(SlotRange slot_number_range = SlotRange(1), int buffer_size = 200,
                  WaitStrategy wait = WaitStrategy::kBlockingStrategy)
        : PortPolicy(slot_number_range), buffer_size_(buffer_size), wait_strategy_(wait) {}

    int buffer_size() const { return buffer_size_; }
    WaitStrategy wait_strategy() const { return wait_strategy_; }

    void set_buffer_size(int sz) { buffer_size_ = sz; }

   protected:
    int buffer_size_;             // output slot only
    WaitStrategy wait_strategy_;  // ouput slot only
};
