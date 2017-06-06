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

#include "device_manager.hpp"
#include "exceptions.hpp"
#include "device.hpp"

namespace device {

DeviceManager::DeviceManager() {}
    
DeviceManager& DeviceManager::instance() {
    static DeviceManager manager;
    return manager;
}

Subscription DeviceManager::Subscribe() {
    return Subscription();
}

void DeviceManager::AddDevice(std::string id, std::string type,
                              std::string address, const YAML::Node & options,
                              const YAML::Node & adapter_options) {
    // no device with same id
    if (devices_.count(id)) {
        throw DeviceError("Device with id " + id + " already exists.");
    }
    
    // construct device
    std::shared_ptr<Device> device;
    try {
        device.reset( DeviceFactory::instance().create( type ) );
        device->Setup(id, type, address, options, adapter_options);
    } catch (factory::UnknownClass &e) {
        throw DeviceError("Cannot add device " + id + " (device type " + type + " is unknown).");
    }
    
    address = device->properties().address();
    
    // no device with same type/address combi
    if (device_mapper_.count(std::make_pair(type, address))) {
        throw DeviceError("Duplicate device of type " + type + " (id=" + id + ", address=" + address + ").");
    }
    
    // add to maps
    devices_[id] = device;
    device_mapper_[std::make_pair(type, address)] = id;
}

void DeviceManager::RemoveDevice(std::string id) {
    // check if device is in use (i.e. reserved)
    // if not, remove from maps
    throw NotImplemented("DevicePool::RemoveDevice");
}

void DeviceManager::RemoveAll() {
    // loop through devices
    // check if device is in use (i.e. reserved)
    // if not, remove from maps
    throw NotImplemented("DevicePool::RemoveAll");
}

bool DeviceManager::HasDevice(std::string id) {
    // check if id is key in map
    return (devices_.count(id) > 0);
}

bool DeviceManager::HasDevice(std::string type, std::string address) {
    // check if <type,address> is key in map
    return (device_mapper_.count(std::make_pair(type, address)) > 0);
}

Device* DeviceManager::DeviceByID(std::string id) {
    if (!devices_.count(id)) {
        throw DeviceError("No device named " + id +".");
    }
    return devices_[id].get();
}

const Device * DeviceManager::DeviceByID(std::string id) const {
    if (!devices_.count(id)) {
        throw DeviceError("No device named " + id +".");
    }
    return devices_.at(id).get();
}

void Subscription::ReleaseInterface(std::string id, std::string interface) {
    if (id.empty()) { interfaces_.clear(); }
    else if (interface.empty()) {
        for (auto it = interfaces_.begin(); it != interfaces_.end(); ) {
            if( it->first.first == id ) { it = interfaces_.erase(it); }
            else { ++it; }
        }
    } else {
        interfaces_.erase( {id, interface} );
    }
} 

}  // namespace device
