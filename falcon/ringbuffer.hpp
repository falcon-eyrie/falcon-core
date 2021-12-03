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

#include "disruptor/batch_descriptor.h"
#include "disruptor/claim_strategy.h"
#include "disruptor/interface.h"
#include "disruptor/ring_buffer.h"
#include "disruptor/wait_strategy.h"


/**
 * this RingBuffer implementation is based on the disruptor::RingBuffer
 * but it stores the data objects in a vector

 * Ring based store of reusable entries containing the data representing an
 * event being exchanged between publisher and {@link EventProcessor}s.
 *
 * @param <T> implementation storing the data for sharing during exchange
 *  or parallel coordination of an event.
 */

template<typename T>
class RingBuffer : public disruptor::Sequencer {
 public:

    /**
     * Construct a RingBuffer with the full option set.
     *
     * @param prototype of data object to store in ringbuffer
     * @param buffer_size of the RingBuffer, must be a power of 2.
     * @param claim_strategy_option threading strategy for publishers claiming
     * entries in the ring.
     * @param wait_strategy_option waiting strategy employed by
     * processors_to_track waiting in entries becoming available.
     */
    RingBuffer(const T & prototype,
               int buffer_size,
               disruptor::ClaimStrategyOption claim_strategy_option,
               disruptor::WaitStrategyOption wait_strategy_option) :
            disruptor::Sequencer(buffer_size,
                      claim_strategy_option,
                      wait_strategy_option),
            buffer_size_(buffer_size),
            mask_(buffer_size - 1),
            events_(buffer_size, prototype) {
    }

    /**
     * Get the event for a given sequence in the RingBuffer.
     *
     * @param sequence for the event
     * @return event pointer at the specified sequence position.
     */

    T* Get(const int64_t& sequence) {
        return &events_[sequence & mask_];
    }

 private:
    // Members
    int buffer_size_;
    int mask_;
    std::vector<T> events_;

    DISALLOW_COPY_AND_ASSIGN(RingBuffer);
};

typedef disruptor::ProcessingSequenceBarrier RingBarrier;

typedef disruptor::Sequence RingSequence;

typedef disruptor::ClaimStrategyOption ClaimStrategy;
typedef disruptor::WaitStrategyOption WaitStrategy;
typedef disruptor::AlertException RingAlertException;

typedef disruptor::BatchDescriptor RingBatch;
