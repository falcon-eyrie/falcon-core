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

#include "streamports.hpp"

int IdentifyNextSlot(int slot_request, int connected_slot_number,
                     bool allow_multi_connect, const PortPolicy &policy) {
    if (slot_request >= policy.max_slot_number()) {
        return -1;
    }

    // auto select first available slot
    if (slot_request < 0) {
        if (allow_multi_connect) {
            return connected_slot_number % policy.max_slot_number();
        } else if (connected_slot_number < policy.max_slot_number()) {
            return connected_slot_number;
        } else {
            return -1;
        }
    }

    // requested already connected slot
    if (slot_request < connected_slot_number) {
        if (allow_multi_connect) {
            return slot_request;
        } else {
            return -1;
        }
    }

    if (slot_request < policy.min_slot_number()) {
        return slot_request;
    }

    if (slot_request >= policy.min_slot_number() &&
        slot_request == connected_slot_number) {
        return slot_request;
    }

    return -1;
}
