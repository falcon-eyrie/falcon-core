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

#include "device_common.hpp"

#include <random>

namespace device {
    
bool Resources::is_device() const {
    return this->size()==1 && this->count(WHOLEDEVICE)==1;
}

bool Resources::is_shared_device() const {
    return is_device() && this->at(WHOLEDEVICE);
}

bool Resources::is_exclusive_device() const {
    return is_device() && !this->at(WHOLEDEVICE);
}

bool Resources::all_shared() const {
    bool b = true;
    for (auto & it : *this) {
        b &= it.second;
    }
    return b;
}

bool Resources::any_exclusive() const {
    bool b = false;
    for (auto & it : *this) {
        b |= !it.second;
    }
    return b;
}

std::string Resources::to_string() const {
    std::string s;
    for (auto & it : *this) {
        s += it.first + ":";
        s += it.second ? "s" : "x";
        s += " ";
    }
    return s;
}


Reservation::Reservation() {}

Reservation::Reservation(uint64_t subscription, const Resources & resources)
  : subscription_(subscription), resources_(resources) {}

Reservation::Reservation(const Reservation & other)
  : subscription_(other.subscription_),
    resources_(other.resources_) {}

uint64_t Reservation::subscription() const { return subscription_; }
const Resources & Reservation::resources() const { return resources_; }


ReservationID ReservationID::create() {
    ReservationID r;
    r.push_back( generate_unique_number() );
    return r;
}

void ReservationID::add(const ReservationID & other) {
    for (auto & it : other) {
        this->push_back(it);
    }
}

ReservationID::operator bool() const { return this->size()>0; }

uint64_t ReservationID::generate_unique_number() {
    static std::mt19937 eng{std::random_device{}()};
    static std::uniform_int_distribution<uint64_t> dist{1, std::numeric_limits<uint64_t>::max()};
    return dist(eng);
}


PropertiesBase::PropertiesBase(std::string type, bool default_shared)
  : type_(type), default_shared_(default_shared) {
    clear_resources();
}
    
std::string PropertiesBase::type() const { return type_; }

const Resources PropertiesBase::resources() const { return resources_; }
    
void PropertiesBase::set_resource(std::string resource_name, bool shared) {
    if (resource_name == WHOLEDEVICE && resources_.count(WHOLEDEVICE)==0) {
        // special whole device resource cannot be combined with other resources
        throw std::runtime_error("Whole device resource cannot be combined with other resources.");
    } 
    
    resources_[resource_name] = shared;
    
    if (resource_name!=WHOLEDEVICE) {
        resources_.erase(WHOLEDEVICE);
    }
    
}
    
void PropertiesBase::remove_resource(std::string name) {
    resources_.erase(name);
    if (resources_.size()==0) {
        clear_resources();
    }
}
    
bool PropertiesBase::has_resource(std::string name) {
    return resources_.count(name)==1;
}

void PropertiesBase::clear_resources() {
    resources_.clear();
    resources_[WHOLEDEVICE] = default_shared_;
}

std::string PropertiesBase::to_string() const {
    std::string s;
    s += "type = " + type_;
    s += ", resources = { ";
    
    s += resources_.to_string();
    
    s += "}";
    
    return s;
}

void PropertiesBase::set_resources(const Resources & resources) {
    resources_ = resources;
}


DeviceProperties::DeviceProperties() {}
DeviceProperties::DeviceProperties(std::string name, std::string type)
  : PropertiesBase(type), name_(name) {}
    
std::string DeviceProperties::name() const { return name_; }
std::string DeviceProperties::address() const { return address_; }

void DeviceProperties::set_address(std::string value) {
    address_ = value;
}

std::string DeviceProperties::to_string() const {
    std::string s;
    s += "name = " + name_;
    s += ", address = " + address_ + ", ";
    s += PropertiesBase::to_string();
    return s;
}

}  // namespace device
