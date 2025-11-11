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

#include "sharedstate.hpp"

#include <string>
#include <vector>

Permission permission_from_string(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(), ::tolower);
    if (s == "none") {
        return Permission::NONE;
    } else if (s == "read") {
        return Permission::READ;
    } else if (s == "write") {
        return Permission::WRITE;
    } else {
        throw std::runtime_error("Unknown permission value.");
    }
}

std::string permission_to_string(Permission p, bool shorthand) {
    std::string s;
    if (shorthand) {
        if (p == Permission::READ) {
            s = "read";
        } else if (p == Permission::WRITE) {
            s = "write";
        } else {
            s = "none";
        }
    } else {
        if (p == Permission::READ) {
            s = "R";
        } else if (p == Permission::WRITE) {
            s = "W";
        } else {
            s = "N";
        }
    }

    return s;
}

Permissions::Permissions(Permission self, Permission others,
                         Permission external)
    : self_(self), others_(others), external_(external) {}

const Permission Permissions::self() const { return self_; }
const Permission Permissions::others() const { return others_; }
const Permission Permissions::external() const { return external_; }

void Permissions::set_self(const Permission p) { self_ = p; }
void Permissions::set_others(const Permission p) { others_ = p; }
void Permissions::set_external(const Permission p) { external_ = p; }

std::string Permissions::to_string(bool shorthand) const {
    std::string s;
    std::string delimiter = "";

    if (!shorthand) {
        delimiter = "|";
    }

    s += permission_to_string(self_) + delimiter;
    s += permission_to_string(others_) + delimiter;
    s += permission_to_string(external_);

    return s;
}

bool Permissions::IsCompatible(const Permissions &p) {
    return !(others_ == Permission::NONE || p.others() == Permission::NONE ||
             (others_ == Permission::READ && p.self() != Permission::READ) ||
             (self_ != Permission::READ && p.others() == Permission::READ));
}

IState::IState(const Permissions &permissions, std::string description)
    : permissions_(permissions), description_(description), shared_(false),
      external_permission_(
          std::make_shared<ExternalPermissionTracker>(permissions.external())) {
}

IState::IState(const IState &other)
    : IState(other.permissions_, other.description_) {}

bool IState::IsCompatible(const Permissions &permissions) {
    return this->permissions_.IsCompatible(permissions);
}

const Permissions &IState::permissions() const {
    return permissions_;
} // read-only

Permission IState::external_permission() {
    return external_permission_->permission();
}

std::string IState::description() { return description_; }

bool IState::IsShared() { return shared_; }

void IState::set_description(std::string value) { description_ = value; }

void IState::set_external_permission(Permission permission) {
    external_permission_->add(permission);
    external_permission_->subtract(permissions_.external());
    permissions_.set_external(permission);
}

void IState::lock() {
    while (lock_.test_and_set(std::memory_order_acquire)) {
    }
}

void IState::unlock() { lock_.clear(std::memory_order_release); }

SharedStateAlias::SharedStateAlias(Permission external, std::string description)
    : external_(external), description_(description) {}

SharedStateAlias::~SharedStateAlias() { RemoveAllStates(); }

void SharedStateAlias::AddState(std::string name,
                                const std::shared_ptr<IState> &dependent) {
    // already part of group
    if (dependents_.count(name)) {
        return;
    }

    // check for compatibility against existing dependents
    for (auto const &state : dependents_) {
        if (!dependent->IsLikeMe(state.second) ||
            !dependent->IsCompatible(state.second->permissions())) {
            throw std::runtime_error(
                "New state \"" + name + "\" (" +
                state.second->permissions().to_string() +
                ") is not compatible with existing state (" +
                dependent->permissions().to_string() + ")");
        }
    }

    if (dependents_.size() == 0) {
        // create master state
        master_ = std::shared_ptr<IState>(dependent->clone());
        master_->set_external_permission(external_);
    }

    dependent->Share(master_);
    dependents_[name] = dependent;
}

void SharedStateAlias::RemoveState(std::string name) {
    if (dependents_.count(name)) {
        dependents_[name]->UnShare();
        dependents_.erase(name);
    }
    if (dependents_.size() == 0) {
        master_.reset();
    }
}

void SharedStateAlias::RemoveAllStates() {
    for (auto const &state : dependents_) {
        state.second->UnShare();
    }
    dependents_.clear();
    master_.reset();
}

bool SharedStateAlias::Update(std::string value) {
    if (!master_) {
        throw std::runtime_error("Alias is not linked to states.");
    }
    return master_->set_string(value);
}

std::string SharedStateAlias::Retrieve() {
    if (!master_) {
        throw std::runtime_error("Alias is not linked to states.");
    }
    return master_->get_string();
}

YAML::Node SharedStateAlias::ExportYAML() {
    YAML::Node alias_description;

    for (auto &it : dependents_) {
        alias_description["states"].push_back(it.first);
    }
    if (external_ == Permission::READ || external_ == Permission::WRITE) {
        alias_description["value"] = Retrieve();
    }
    alias_description["description"] = description_;

    return alias_description;
}

SharedStateMap::~SharedStateMap() { clear(); }

void SharedStateMap::AddAlias(std::string alias, Permission permission,
                              std::string description) {
    if (aliases_.count(alias)) {
        throw std::runtime_error("Shared state alias already exists.");
    }
    aliases_.emplace(std::piecewise_construct, std::make_tuple(alias),
                     std::make_tuple(permission, description));
}

void SharedStateMap::RemoveAlias(std::string alias) { aliases_.erase(alias); }

void SharedStateMap::ShareState(std::string alias, std::string name,
                                std::shared_ptr<IState> state) {
    if (aliases_.count(alias) == 0) {
        throw std::runtime_error("Group does not exist.");
    }

    // if state already linked, unlink first
    if (IsShared(name)) {
        if (shared_states_[name] == alias) {
            return;
        } else {
            UnShareState(name);
        }
    }

    // try add state to group
    aliases_[alias].AddState(name, state);
    shared_states_[name] = alias;
}

void SharedStateMap::UnShareState(std::string name) {
    if (IsShared(name)) {
        aliases_[shared_states_[name]].RemoveState(name);
        shared_states_.erase(name);
    }
}

void SharedStateMap::UnShareAll() {
    for (auto const &state : shared_states_) {
        aliases_[state.second].RemoveState(state.first);
    }
    shared_states_.clear();
}

void SharedStateMap::clear() {
    UnShareAll();
    aliases_.clear();
}

bool SharedStateMap::IsShared(std::string name) {
    return (shared_states_.count(name) == 1);
}

std::vector<std::string> SharedStateMap::ListSharedStates(std::string alias) {
    std::vector<std::string> state_list;
    for (auto const &imap : shared_states_) {
        state_list.push_back(imap.first);
    }
    return state_list;
}

bool SharedStateMap::UpdateAlias(std::string alias, std::string value) {
    if (aliases_.count(alias) == 0) {
        throw std::runtime_error("No alias named " + alias);
    }
    return aliases_[alias].Update(value);
}

std::string SharedStateMap::RetrieveAlias(std::string alias) {
    if (aliases_.count(alias) == 0) {
        throw std::runtime_error("No alias named " + alias);
    }
    return aliases_[alias].Retrieve();
}

YAML::Node SharedStateMap::ExportYAML() {
    YAML::Node node;

    for (auto &it : this->aliases_) {
        node[it.first] = it.second.ExportYAML();
    }

    return node;
}
