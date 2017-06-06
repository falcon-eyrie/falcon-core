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

#ifndef DEVICEMANAGER_HPP
#define DEVICEMANAGER_HPP

#include "yaml-cpp/yaml.h"

#include <string>
#include <map>
#include <memory>
#include <utility>

#include "device.hpp"

namespace graph {
class ProcessorGraph;
}

namespace device {
    
class Subscription;

class DeviceManager {

friend class graph::ProcessorGraph;
friend class Subscription;

public:
    bool HasDevice(std::string id);
    bool HasDevice(std::string type, std::string address);
    
    static Subscription Subscribe();
    
    static DeviceManager & instance();
    
    const Device * DeviceByID(std::string id) const;
    
protected:
    DeviceManager();
    
    // called by ProcessorGraph to add new device
    void AddDevice(std::string id, std::string type, std::string address,
                   const YAML::Node & options, const YAML::Node & adapter_options);
    
    // called by ProcessorGraph to remove devices
    void RemoveDevice(std::string id);
    void RemoveAll();
    
    // called by Subscription::ReserveInterface to get device
    Device* DeviceByID(std::string id);
    
protected:
    std::map<std::string, std::shared_ptr<Device>> devices_;  // key = device id; value = device
    std::map<std::pair<std::string, std::string>, std::string> device_mapper_; // key = device type, device address; value = device id
};


class Subscription {
public:
    Subscription() : unique_id_( generate_unique_number() ) {}
    
    bool operator ==(const Subscription & other) { return unique_id_ == other.unique_id_; }
    
    template <class DEVICE>
    DEVICE* ReserveDevice(std::string id) { return nullptr; }
    
    template <class IFACE>
    IFACE* ReserveInterface(std::string id, std::string interface, const YAML::Node & options) {
        
        IFACE* out;
        
        if (interfaces_.count({id,interface}) > 0) {
            // interface already exists
            out = dynamic_cast<IFACE*>( interfaces_[{id,interface}].get() );
            if (!out) { throw std::runtime_error("Error casting interface."); }
        } else {
            // find device
            auto device = DeviceManager::instance().DeviceByID(id);
            // and construct new interface
            std::unique_ptr<Interface> p = device->ReserveInterface(unique_id_, interface, options);
            
            out = dynamic_cast<IFACE*>(p.get());
            
            if (out == nullptr) { throw std::runtime_error("Error casting interface."); }
            
            // store interface
            interfaces_[{id,interface}] = std::move(p);
        }
        
        return out;
    }
    
    void ReleaseInterface(std::string id = "", std::string interface = "");

private:
    static uint64_t generate_unique_number() {
        static std::mt19937 eng{std::random_device{}()};
        static std::uniform_int_distribution<uint64_t> dist{1, std::numeric_limits<uint64_t>::max()};
        return dist(eng);
    }

private:
    uint64_t unique_id_;
    std::map<std::pair<std::string,std::string>,std::unique_ptr<Interface>> interfaces_;
};

}  // namespace device

#endif  // DEVICEMANAGER_HPP
