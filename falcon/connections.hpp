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

#include <string>

class PortAddress {
  public:
    PortAddress(std::string processor, std::string port)
        : processor_name_(processor), port_name_(port), processor_class_("?"),
          port_datatype_("?") {}

    const std::string processor() const { return processor_name_; }
    const std::string port() const { return port_name_; }

    const std::string processor_class() const { return processor_class_; }
    const std::string port_datatype() const { return port_datatype_; }

    void set_port(std::string port, std::string port_datatype = "?") {
        port_name_ = port;
        port_datatype_ = port_datatype;
    }

    void set_port_datatype(std::string datatype) { port_datatype_ = datatype; }
    void set_processor_class(std::string klass) { processor_class_ = klass; }
    const std::string string(bool full = false) const;

  protected:
    std::string processor_name_;
    std::string port_name_;
    std::string processor_class_;
    std::string port_datatype_;
};

class SlotAddress : public PortAddress {
  public:
    SlotAddress(std::string processor, std::string port, int slot)
        : PortAddress(processor, port), slot_(slot) {}

    SlotAddress(const PortAddress &port, int slot)
        : PortAddress(port), slot_(slot) {}

    int slot() const { return slot_; }

    void set_slot(int slot) { slot_ = slot; }

    const std::string string(bool full = false) const;

  protected:
    int slot_;
};
