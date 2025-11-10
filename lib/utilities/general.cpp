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

#include "general.hpp"
#include <cmath>
#include <string>

void EventCounter::reset() {
    all_received = 0;
    target = 0;
    non_target = 0;
}

static int check_buffer_sizes(
    // can return:
    // -2: no check passed;
    // -1: loose check passed, but required strict check failed;
    //  1: loose checked passed (strict check not required))
    //  2: both checks passed (independent of the request required)
    double incoming,
    double &outgoing, // can be changed inside if no strict check is present
    bool strict_check,
    size_t &n); // number of incoming/upstream buffer-size that must be
                // integrated to obtain one outgoing/downstream buffer-size

int check_buffer_sizes(double incoming, double &outgoing, bool strict_check,
                       size_t &n) {
    if (incoming > outgoing) {
        outgoing = incoming;
        n = 1;
        return -2;
    }

    if (!compare_doubles(
            remainder(outgoing, incoming))) { // check remainder is zero
        if (!strict_check) {
            n = round(outgoing / incoming);
            outgoing = n * incoming;
            return 1;
        }
        n = 0;
        return -1;
    }
    n = outgoing / incoming;
    return 2;
}

void check_buffer_sizes_and_log(double incoming, double &outgoing,
                                bool strict_check, size_t &n,
                                std::string processor_name) {
    double outgoing_copy = outgoing;
    switch (check_buffer_sizes(incoming, outgoing, strict_check, n)) {
    case -2:
        throw std::runtime_error(
            processor_name +
            ". Selected outgoing buffer size must be higher or equal to the "
            "incoming buffer size (" +
            std::to_string(incoming) + " ms, requested (outgoing): " +
            std::to_string(outgoing_copy) + " ms)");
    case -1:
        throw std::runtime_error(
            processor_name +
            ". Selected outgoing buffer size must be an exact multiple of the "
            "incoming buffer size (" +
            std::to_string(incoming) + " ms, requested (outgoing): " +
            std::to_string(outgoing_copy) + " ms)");
    case 1:
        // LOG(UPDATE) << processor_name << ". Outgoing buffer size was adjusted
        // to"
        //            << outgoing_copy << " ms.";
        break;
    }
}
