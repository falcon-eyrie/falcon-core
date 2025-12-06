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

#include <algorithm>
#include <atomic>
#include <iostream>
#include <map>
#include <memory>
#include <set>
#include <sstream>
#include <string>
#include <typeinfo>
#include <vector>

#include "logging/log.hpp"
#include "yaml-cpp/yaml.h"

// a state wraps a value that is possibly shared between threads
// access to the value should be protected (atomic or lock)
// a state has a non-shared cached value that is synchronized with every set/get
// operation (optional) on the state the cache is useful for checking if the
// value was changed outside of the state since the last set/get operation

// TODO: take state retrieval/update out of IProcessor and make it
// responsibility of ProcessorGraph IProcessors should only be allowed to
// set/get state value (and not change permissions, (un)share, etc.)
// ProcessorGraph is responsible for moderating external access (including
// permission check) ProcessorGraph is responsible for (un)linking states

// ProcessorGraph owns a LinkedStateMap that manages LinkedStateGroups
// shared states are linked to each other (managed by a LinkedStateGroup)
// processor.state can be added/removed (by name) to/from LinkedStateGroup

// ProcessorGraph::Update/Retrieve
//   global-state: value
//   processor: {state: value}

enum class Permission { NONE = 0, READ, WRITE };  // in order of least permissive to most permissive

Permission permission_from_string(std::string s);
std::string permission_to_string(Permission p, bool shorthand = false);

class ExternalPermissionTracker {
   public:
    ExternalPermissionTracker() : none_(0), read_(0), write_(0) {}
    ExternalPermissionTracker(Permission permission) : ExternalPermissionTracker() {
        add(permission);
    }

    Permission permission() {
        if (none_.load() > 0) {
            return Permission::NONE;
        }
        if (read_.load() > 0) {
            return Permission::READ;
        }
        if (write_.load() > 0) {
            return Permission::WRITE;
        }
        return Permission::NONE;
    }

    void add(Permission permission) {
        if (permission == Permission::NONE) {
            ++none_;
        } else if (permission == Permission::READ) {
            ++read_;
        } else if (permission == Permission::WRITE) {
            ++write_;
        }
    }

    void subtract(Permission permission) {
        if (permission == Permission::NONE) {
            --none_;
        } else if (permission == Permission::READ) {
            --read_;
        } else if (permission == Permission::WRITE) {
            --write_;
        }
    }

   protected:
    std::atomic<int> none_;
    std::atomic<int> read_;
    std::atomic<int> write_;
};

class Permissions {
   public:
    Permissions(Permission self = Permission::WRITE, Permission others = Permission::READ,
                Permission external = Permission::NONE);

    const Permission self() const;
    const Permission others() const;
    const Permission external() const;

    void set_self(const Permission p);
    void set_others(const Permission p);
    void set_external(const Permission p);

    std::string to_string(bool shorthand = true) const;
    bool IsCompatible(const Permissions& p);

   protected:
    Permission self_;
    Permission others_;
    Permission external_;
};

class SharedStateAlias;
namespace graph {
class ProcessorGraph;
}

class IState {
    friend class SharedStateAlias;
    friend class graph::ProcessorGraph;

   public:
    IState(const Permissions& permissions, std::string description = "");
    IState(const IState& other);
    virtual ~IState() {}
    virtual IState* clone() const = 0;

    bool IsCompatible(const Permissions& permissions);
    const Permissions& permissions() const;
    Permission external_permission();

    std::string description();
    virtual std::string get_string(bool cache = true) = 0;

   protected:  // for friends only
    virtual bool IsLikeMe(const std::shared_ptr<IState>& other) = 0;

    virtual void Share(const std::shared_ptr<IState>& other) = 0;
    virtual void UnShare() = 0;

    virtual bool IsShared();

    void set_description(std::string value);

    virtual bool set_string(const std::string& value, bool cache = true) = 0;

    void set_external_permission(Permission permission);

   protected:
    void lock();
    void unlock();

   protected:
    Permissions permissions_;
    std::string description_;
    bool shared_;
    std::shared_ptr<ExternalPermissionTracker> external_permission_;

   private:
    std::atomic_flag lock_ = ATOMIC_FLAG_INIT;
};

template <typename Base, typename Derived>
class StateCloneable : public Base {
   public:
    using Base::Base;

    virtual Base* clone() const { return new Derived(static_cast<Derived const&>(*this)); }
};

template <typename T>
class ReadableState : public StateCloneable<IState, ReadableState<T>> {
   public:
    ReadableState(T default_value, std::string description = "",
                  Permission peers = Permission::WRITE, Permission external = Permission::NONE)
        : StateCloneable<IState, ReadableState<T>>(Permissions(Permission::READ, peers, external),
                                                   description),
          default_(default_value),
          cache_(default_value),
          state_(std::make_shared<std::atomic<T>>(default_value)) {}

    ReadableState(const ReadableState& other)
        : StateCloneable<IState, ReadableState<T>>(other.permissions_, other.description_),
          default_(other.default_),
          cache_(other.cache_),
          state_(std::make_shared<std::atomic<T>>(other.state_->load())) {
        // note that we are creating our own (unshared) state
        // and that we do not share other's state
    }

    T get(bool cache = true) {
        T val;
        this->lock();
        val = state_->load();
        if (cache) {
            cache_ = val;
        }
        this->unlock();

        return val;
    }

    bool changed_get(T& val, bool cache = true) {
        bool ret;
        this->lock();
        val = state_->load();
        ret = cache_ == val;
        if (cache) {
            cache_ = val;
        }
        this->unlock();

        return ret;
    }

    std::string get_string(bool cache = true) override {
        if constexpr (std::is_convertible_v<T, std::string>) {
            T value = get(cache);
            if (std::is_same_v<T, bool>) {
                return value ? "true" : "false";
            }
            return std::to_string(value);
        }
        throw std::runtime_error(
            "This state should not have external permission to be read "
            "because it cannot be serialized via string transformation.");
    }

   protected:  // for friends only
    void set(T value, bool cache = true) {
        this->lock();
        state_->store(value);
        if (cache) {
            cache_ = value;
        }
        this->unlock();
    }

    T exchange(T value, bool cache = true) {
        this->lock();
        value = state_->exchange(value);
        if (cache) {
            cache_ = value;
        }
        this->unlock();

        return value;
    }

    bool set_string(const std::string& value, bool cache = true) override {
        if constexpr (std::is_convertible_v<T, std::string>) {
            std::stringstream ss(value);
            T result;
            if ((std::is_same_v<T, bool> and ss >> std::boolalpha >> result) or ss >> result) {
                set(result, cache);
                return true;
            }
        }
        return false;
    }

    void reset() { set(default_); }

    void Share(const std::shared_ptr<IState>& other) override {
        if (other.get() == this) {
            return;
        }

        auto cast = dynamic_cast<ReadableState<T>*>(other.get());
        if (cast) {
            this->lock();
            this->state_ = cast->state_;
            this->external_permission_ = cast->external_permission_;
            this->external_permission_->add(this->permissions_.external());
            this->shared_ = true;
            this->unlock();
        } else {
            throw std::runtime_error("Cannot delegate to incompatible state.");
        }
    }

    void UnShare() override {
        this->lock();
        this->state_ = std::make_shared<std::atomic<T>>(this->state_->load());
        this->external_permission_->subtract(this->permissions_.external());
        this->external_permission_ =
            std::make_shared<ExternalPermissionTracker>(this->permissions_.external());
        this->shared_ = false;
        this->unlock();
    }

    bool IsLikeMe(const std::shared_ptr<IState>& other) override {
        try {
            auto cast = dynamic_cast<const ReadableState<T>*>(other.get());
            if (cast) {
                return true;
            } else {
                return false;
            }
        } catch (const std::bad_cast& e) {
            return false;
        }
    }

   private:
    T default_;
    T cache_;
    std::shared_ptr<std::atomic<T>> state_;  // our own state, that may be shared with others
};

template <typename T>
class WritableState : public ReadableState<T> {
   public:
    WritableState(T default_value, std::string description = "",
                  Permission peers = Permission::READ, Permission external = Permission::NONE)
        : ReadableState<T>(default_value, description, peers, external) {
        this->permissions_.set_self(Permission::WRITE);
    }

    // make set methods publicly available
    void set(T value, bool cache = true) { ReadableState<T>::set(value, cache); }
    T exchange(T value, bool cache = true) { return ReadableState<T>::exchange(value, cache); }
    bool set_string(const std::string& value, bool cache = true) override {
        return ReadableState<T>::set_string(value, cache);
    }
    void reset() { ReadableState<T>::reset(); }
};

class SharedStateAlias {
   public:
    SharedStateAlias(Permission external = Permission::WRITE, std::string description = "");
    ~SharedStateAlias();
    void AddState(std::string name, const std::shared_ptr<IState>& dependent);
    void RemoveState(std::string name);
    void RemoveAllStates();
    bool Update(std::string value);
    std::string Retrieve();
    YAML::Node ExportYAML();

   private:
    Permission external_;
    std::string description_;
    std::shared_ptr<IState> master_;
    std::map<std::string, std::shared_ptr<IState>> dependents_;
};

template <typename T>
using StaticState = ReadableState<T>;
template <typename T>
using FollowerState = ReadableState<T>;
template <typename T>
using ProducerState = WritableState<T>;
template <typename T>
using BroadcasterState = WritableState<T>;

class SharedStateMap {
   public:
    SharedStateMap() {}
    ~SharedStateMap();
    void AddAlias(std::string alias, Permission permission = Permission::WRITE,
                  std::string description = "");
    void RemoveAlias(std::string alias);
    void ShareState(std::string alias, std::string name, std::shared_ptr<IState> state);
    void UnShareState(std::string name);
    void UnShareAll();
    void clear();
    bool IsShared(std::string name);
    std::vector<std::string> ListSharedStates(std::string alias);
    bool UpdateAlias(std::string alias, std::string value);
    std::string RetrieveAlias(std::string alias);
    YAML::Node ExportYAML();

   protected:
    std::map<std::string, SharedStateAlias> aliases_;
    std::map<std::string, std::string> shared_states_;
};
