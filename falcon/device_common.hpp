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

#ifndef DEVICE_COMMON_HPP
#define DEVICE_COMMON_HPP

#include <map>
#include <string>
#include <deque>
#include <limits>

namespace device {
    
const std::string WHOLEDEVICE = "-";

class Resources : public std::map<std::string,bool> {
public:
    
    bool is_device() const;
    bool is_shared_device() const;
    bool is_exclusive_device() const;
    bool all_shared() const;
    bool any_exclusive() const;
    
    std::string to_string() const;
};

class Reservation {
public:
    Reservation();

    Reservation(uint64_t subscription, const Resources & resources);
    
    Reservation(const Reservation & other);
    
    uint64_t subscription() const;
    const Resources & resources() const;
    
protected:
    uint64_t subscription_;
    Resources resources_;
};

class ReservationID : public std::deque<uint64_t> {
public:
    
    static ReservationID create();
    
    void add(const ReservationID & other);
    
    operator bool() const;
    
private:
    static uint64_t generate_unique_number();
};


class PropertiesBase {
public:
    PropertiesBase(std::string type="", bool default_shared = false);
    
    std::string type() const;
    
    void set_resource(std::string resource_name, bool shared = false);
    void remove_resource(std::string name);
    bool has_resource(std::string name);
    void clear_resources();
    const Resources resources() const;
    void set_resources(const Resources & resources);
    
    virtual std::string to_string() const;
    
protected:
    std::string type_;
    bool default_shared_;
    Resources resources_;
};

class InterfaceProperties : public PropertiesBase {
public:
    InterfaceProperties(std::string type="") : PropertiesBase(type, true) {}
};

class DeviceProperties : public PropertiesBase {
public:
    DeviceProperties();
    DeviceProperties(std::string name, std::string type);
    
    std::string name() const;
    std::string address() const;
    
    void set_address(std::string value);
    
    virtual std::string to_string() const override;
    
protected:
    std::string name_;
    std::string address_;
};

}  // namespace device

#endif  // DEVICE_COMMON_HPP
