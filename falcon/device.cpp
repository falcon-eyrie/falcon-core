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

#include "device.hpp"

#include <algorithm>

namespace device {

Interface::~Interface() {
    LOG(DEBUG) << "Destroying interface.";
    if (reserved_) {
        try {
            device_->ReleaseResources(reservation_);
        } catch (...) {
            // should not happen :(
            LOG(DEBUG) << "Unexpected error when releasing interface.";
        }
    }
}

void Interface::Setup(std::string type, Device* device, const YAML::Node & options) {
    properties_ = InterfaceProperties(type);
    device_ = device;
    Configure(properties_, options);
    LOG(DEBUG) << "Configured interface (device: " << device->to_string() << ") : " << properties_.to_string();
}

void Interface::setReservation(const ReservationID & r) {
    if (reserved_) {
        throw InternalError("Interface::setReservation", "Multiple reservations.");
    }
    reservation_ = r;
    reserved_ = true;
}
    

void Device::Configure(DeviceProperties & props, const YAML::Node & options) {}
const DeviceProperties & Device::properties() const { return properties_; }
    

// called by friend DeviceManager::Subscription
void Device::Setup(std::string name, std::string device_type,
                   std::string address, const YAML::Node & options,
                   const YAML::Node & adapter_options) {
    
    properties_ = DeviceProperties(name, device_type);
    
    SetDefaultProperties(properties_);
    
    if (!address.empty()) {
        properties_.set_address( address );
    }
    
    Configure(properties_, options);
    LOG(DEBUG) << "Configured device: " << this->to_string();
     
    ConstructAdapters(adapter_options);
}

void SetDefaultProperties(DeviceProperties & props) {}

// called internally by Setup
void Device::ConstructAdapters(const YAML::Node & options) {
    
    std::vector<std::pair<std::string,std::string>> adapters = AdapterFactory::instance().listEntries();
    
    for (auto const & adapter : adapters) {
        if (adapter.first != properties().type()) { continue; }
        adapters_[adapter.second] = std::unique_ptr<Adapter>( AdapterFactory::instance().create(adapter, *this));
        adapters_[adapter.second]->Setup(properties_.name(), adapter.second, "",
            options[adapter.second] ? options[adapter.second] : YAML::Node(),
            options[adapter.second] && options[adapter.second]["adapters"] ? options[adapter.second]["adapters"] : YAML::Node());
        LOG(DEBUG) << "Constructed " << adapter.second << " adapter for device " << properties_.name();
    }
}

bool Device::supports(std::string iface, bool cascade) {
    
    bool b = InterfaceFactory::instance().hasClass({properties_.type(),iface});
    
    if (!b && cascade) {
        for (auto & adapter : adapters_) {
            b = adapter.second->supports(iface, cascade);
            if (b) { break; }
        }
    }
    
    return b;
}


std::set<std::string> Device::adapters() const {
    std::set<std::string> s;
    for (auto & it : adapters_) {
        s.insert(it.first);
    }
    return s;
}

std::set<std::string> Device::interfaces() const {
    std::set<std::string> s;
    
    auto ifaces = InterfaceFactory::instance().listEntries();
    
    for (auto & k : ifaces) {
        if (k.first == properties().type()) {
            s.insert(k.second);
        }
    }
    
    for (auto & it : adapters_) {
        auto other = it.second->interfaces();
        s.insert( other.cbegin(), other.cend() );
    }
    
    return s;
}


std::unique_ptr<Interface> Device::ReserveInterface(uint64_t subscription, std::string iface, const YAML::Node & options) {
    
    std::unique_ptr<Interface> p;
    
    if (supports(iface, false)) {
        p.reset( InterfaceFactory::instance().create({properties_.type(),iface}) );
        p->Setup(iface, this, options);
        // reserve resources
        auto rID = ReserveResources({subscription, p->properties().resources()});
        p->setReservation(rID);
    } else {  // delegate to adapters
        for (auto & adapter : adapters_) {
            if (adapter.second->supports(iface)) {
                p = adapter.second->ReserveInterface(subscription, iface, options);
                break;
            }
        }
        
        if (p == nullptr) {
            throw DeviceError("This device does not support this interface.");
        }
    }
    
    return p;
}

ReservationID Device::ReserveResources(const Reservation& reservation) {
    lock();
    if (!check_resource_availability(reservation)) {
        unlock();
        throw std::runtime_error("Requested resources are in use!");
    }
    
    auto r = ReservationID::create();
    reservations_[r.back()] = reservation;
    unlock();
    
    return r;
}

ReservationID Device::ReleaseResources(ReservationID reservation) {
    LOG(DEBUG) << "Releasing resources " << reservations_.at(reservation.back()).resources().to_string();
    lock();
    reservations_.erase( reservation.back() );
    unlock();
    reservation.pop_back();
    return reservation;
}

bool Device::check_resource_availability(const Reservation & request) {
    
    // double check if all requested resources are in device
    //for (auto & it : resources) {
        //if (it.first != WHOLEDEVICE && properties().resources().count(it.first) == 0) {
            //throw InternalError("Device::check_resource_availability", "Requested resources are not supported by this device.");
        //}
    //}
    
    using T = std::map<uint64_t, Reservation>::value_type;
    
    uint64_t subscription = request.subscription();
    bool b = true;
    
    if (request.resources().is_exclusive_device() || properties().resources().is_exclusive_device()) {
        // the device is for exclusive use or the request is for exclusive use of the device
        // only OK if there are no prior reservations or all reservations have the same subscription
        b = (reservations_.size() == 0) ||
            std::all_of(reservations_.cbegin(), reservations_.cend(),
            [subscription](T value) {return value.second.subscription() == subscription;} );
            
    } else if (std::any_of( reservations_.cbegin(), reservations_.cend(),
               [subscription](T value) { return value.second.resources().is_exclusive_device() &&
                                                value.second.subscription()!=subscription; } )) {
        // there is a prior reservation for exclusive use of the whole device
        // with a different subscription
        b = false;
        
    } else if (properties().resources().is_shared_device()) {
        // everyone is sharing the whole device or not
        b = request.resources().is_shared_device() &&
            std::all_of(reservations_.cbegin(), reservations_.cend(),
                        [](T value) { return value.second.resources().is_shared_device(); } ) ;
        
    } else {
        
        for (auto & reservation : reservations_) {
            
            if (subscription == reservation.second.subscription()) {
                continue;
            }
            
            if (request.resources().is_shared_device()) {
                for (auto & device_resource : properties().resources()) {
                    b &= (device_resource.second && 
                         (reservation.second.resources().count(device_resource.first)==0 ||
                          !reservation.second.resources().is_device() ) ) ||
                         (device_resource.second &&
                         (reservation.second.resources().count(device_resource.first)==0 ||
                          reservation.second.resources().at(device_resource.first) ||
                          reservation.second.resources().is_shared_device()));
                }
            }
            
            if (!b) {break;}
            
            for (auto & requested_resource : request.resources()) {
                if (!requested_resource.second ||  //exclusive request
                    !properties().resources().at(requested_resource.first)) {  // or exclusive resource
                    // only OK if the prior reservation does not use this resource
                    b &= reservation.second.resources().count(requested_resource.first) == 0 &&
                         !reservation.second.resources().is_device();
                } else {  // shared request, shared resource
                    // OK if reservation is not using or sharing resource
                    b &= reservation.second.resources().count(requested_resource.first) == 0 ||
                         reservation.second.resources().is_shared_device() ||
                         reservation.second.resources().at(requested_resource.first);
                }
            }
            
            if (!b) { break; }
        }
        
    }

    return b;
}



Reservation Adapter::AdaptReservation(const Reservation & r) {
    // by default, perfect forwarding of resources
    return r;
}

void Adapter::SetDefaultProperties(DeviceProperties & props) {
    // copy adaptee resources
    props.set_resources( adaptee_.properties().resources() );
    props.set_address( adaptee_.properties().address() );
}

ReservationID Adapter::ReserveResources(const Reservation & reservation) {
    
    ReservationID rID;
    
    // first reserve our own resources
    // will throw if it fails
    rID.add( Device::ReserveResources(reservation) );
    
    // next, have adaptee reserve resources
    ReservationID adaptee_rID;
    try {
        adaptee_rID = adaptee_.ReserveResources( AdaptReservation(reservation) );
    } catch (...) {
        // undo our own reservation
        Device::ReleaseResources(rID);
        throw;
    }
    
    rID.add( adaptee_rID );
    
    return rID;
}

ReservationID Adapter::ReleaseResources(ReservationID reservation) {
    return Device::ReleaseResources( adaptee_.ReleaseResources( reservation ) );
}

}  // namespace device
