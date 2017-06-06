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

#ifndef DEVICE_HPP
#define DEVICE_HPP

#include "factory/factory.hpp"
#include "yaml-cpp/yaml.h"

#include "g3log/src/g2log.hpp"

#include "exceptions.hpp"

#include <map>
#include <atomic>

#include "device_common.hpp"

namespace device {

// forward declaration
class Device;

class Interface {
friend class Device;
public:
    Interface() : reserved_(false) {}
    
    virtual ~Interface();
    
    virtual void Configure(InterfaceProperties & props, const YAML::Node & options) {}
    const InterfaceProperties & properties() const { return properties_; }
    
protected:
    virtual void Setup(std::string type, Device* device,
                       const YAML::Node & options);
    
    void setReservation(const ReservationID & r);
    
protected:
    InterfaceProperties properties_;
    Device * device_ = nullptr;
    ReservationID reservation_;
    bool reserved_;
};

using InterfaceFactory = factory::ObjectFactory<Interface, std::pair<std::string, std::string>>;

#define REGISTER_DEVICE_INTERFACE(DEVICE,INTERFACE,IMPL) \
    namespace _registrars { \
        static factory::Registrar<std::pair<std::string, std::string>, device::Interface, IMPL> _interface_ ## DEVICE ## INTERFACE( { #DEVICE, #INTERFACE } ); \
    };

// forward declaration
class Adapter;
class DeviceManager;
class Subscription;

class Device {

friend class DeviceManager;
friend class Subscription;
friend class Adapter;
friend class Interface;

public:
    Device() {}
    Device(const Device & other) = delete;

    virtual void Configure(DeviceProperties & props, const YAML::Node & options);
    const DeviceProperties & properties() const;
    
    bool supports(std::string iface, bool cascade = true);
    
    std::string to_string() const { return properties_.to_string(); }
    
    std::set<std::string> adapters() const;
    std::set<std::string> interfaces() const;
    
    void lock() {
        while (lock_.test_and_set()) {}
    }
    void unlock() {
        lock_.clear();
    }
    
private:
    std::unique_ptr<Interface> ReserveInterface(uint64_t subscription, std::string iface, const YAML::Node & options);
    
    // called by friend Subscription
    void Setup(std::string name, std::string device_type,
               std::string address, const YAML::Node & options,
               const YAML::Node & adapter_options);
    
    virtual void SetDefaultProperties(DeviceProperties & properties) {}
        
    // called internally by Setup
    void ConstructAdapters(const YAML::Node & options);

protected:
    virtual ReservationID ReserveResources(const Reservation & reservation);
    virtual ReservationID ReleaseResources(ReservationID reservation);
    bool check_resource_availability(const Reservation & reservation);

protected:
    std::map<std::string, std::unique_ptr<Adapter>> adapters_;
    DeviceProperties properties_;
    std::map<uint64_t, Reservation> reservations_;
    std::atomic_flag lock_ = ATOMIC_FLAG_INIT;
};

class Adapter : public Device {
public:
    Adapter(Device & adaptee) : adaptee_(adaptee) {}
    
    virtual Reservation AdaptReservation(const Reservation & r);
    
    void SetDefaultProperties(DeviceProperties & props) override;
    
    ReservationID ReserveResources(const Reservation & reservation) override;
    
    ReservationID ReleaseResources(ReservationID reservation) override;
    
protected:
    Device & adaptee_;
};


template <class DEVICE>
class DeviceAdapter : public Adapter {
public:
    DeviceAdapter(Device & adaptee) : Adapter(adaptee) {
        try { dynamic_cast<DEVICE&>(adaptee); }
        catch (std::bad_cast & e) {
            throw DeviceError("Incompatible device adapter. Cannot cast.");
        }
    }
    DEVICE & adaptee() { return static_cast<DEVICE&>(adaptee_); }
};

template <class DEVICE, class IFACE>
class DeviceInterface : public Interface, public IFACE {
public:
    DeviceInterface() {}
    DEVICE* device() { return static_cast<DEVICE*>(this->device_); }
    const DEVICE* device() const { return static_cast<DEVICE*>(this->device_); }
protected:
    void Setup(std::string name, Device* device, const YAML::Node & options) final {
        if (dynamic_cast<DEVICE*>(device) == nullptr) {
            throw DeviceError("Incompatible device type.");
        }
        Interface::Setup(name, device, options);
    }
};


using DeviceFactory = factory::ObjectFactory<Device, std::string>;
#define REGISTERDEVICE(DEVICE) FACTORYREGISTEROBJECT(device::Device,DEVICE)


using AdapterFactory = factory::ObjectFactory<Adapter, std::pair<std::string, std::string>, Device&>;
#define REGISTER_DEVICE_ADAPTER(DEVICE,ADAPTER) \
    namespace _registrars { \
        static factory::Registrar<std::pair<std::string, std::string>, device::Adapter, ADAPTER, device::Device&> _adapter_ ## DEVICE ## ADAPTER( { #DEVICE, #ADAPTER } ); \
    };

}  // namespace device

#endif  // DEVICE_HPP
