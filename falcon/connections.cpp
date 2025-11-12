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

#include "connections.hpp"

const std::string PortAddress::string(bool full) const {
    std::string s;

    if (full) {
        s = processor() + "[" + processor_class() + "]." + port() + "[" +
            port_datatype() + "]";
    } else {
        s = processor() + "." + port();
    }

    return s;
}

const std::string SlotAddress::string(bool full) const {
    auto s = PortAddress::string(full);
    s = s + "." + std::to_string(slot());
    return s;
}
