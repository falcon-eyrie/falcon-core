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
#include <memory>
#include <string>

#include "math_numeric.hpp"

typedef Range<unsigned int> ChannelRange;

// basic event counter
struct EventCounter {
    uint64_t all_received = 0;
    uint64_t target = 0;
    uint64_t non_target = 0;

    inline bool consistent_counters() {
        return all_received == (target + non_target);
    }

    void reset();
};

template <typename T, typename... Args>
std::unique_ptr<T> make_unique(Args &&...args);

template <class T, class A> T join(const A &begin, const A &end, const T &t);

/*
 * This method checks that:
    - outgoing buffer-size is greater or equal to the bin size of the incoming
 buffer size,
    - if strict_check is true, outgoing buffer-size is an exact multiple of the
 bin size of the incoming buffer size.
 * This methods also sets the value of n to the number of multiples and,
 if no strict check required, adjusts the outgoing buffer-size to the closest
 value
 * to the first multiple of the incoming buffer-size
 */
void check_buffer_sizes_and_log(double incoming, double &outgoing,
                                bool strict_check, size_t &n,
                                std::string processor_name);

const double MAX_N_HOURS_TEST = 1.5;
constexpr std::size_t MAX_TEST_SAMPLING_FREQUENCY = 32000;

#include "general.ipp"
