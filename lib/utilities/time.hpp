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

#include <chrono>
#include <cmath>
#include <cstdint>
#include <string>

// define clock for performance measurements
typedef std::chrono::steady_clock Clock;
typedef Clock::time_point TimePoint;

void custom_sleep_for(uint64_t microseconds);

std::string time_to_string(std::time_t t, std::string fmt = "%F %T");

enum class TruncateFlag { ROUND = 0, FLOOR, CEIL };

template <typename T>
T time2samples(double t, double rate, TruncateFlag flag = TruncateFlag::ROUND);

template <typename T> constexpr double samples2time(T nsamples, double rate);

// returns the time difference in seconds between two timestamps
double compute_delta_ts(uint64_t t1, uint64_t t2);

struct TimestampRegister {
    uint64_t hw;
    TimePoint source;

    void reset();
};

#include "time.ipp"
