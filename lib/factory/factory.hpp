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

#include <exception>
#include <iostream>
#include <map>
#include <string>
#include <utility>
#include <vector>

namespace factory {

// exceptions
class UnknownClass : public std::runtime_error {
  public:
    UnknownClass(std::string const &error) : std::runtime_error(error) {}
};
class DuplicateClass : public std::runtime_error {
  public:
    DuplicateClass(std::string const &error) : std::runtime_error(error) {}
};

template <typename AbstractObject, typename... Args>
using ObjectCreator = AbstractObject *(*)(Args && ...);

template <typename AbstractObject, typename IdentifierType, typename... Args>
class ObjectFactory {
    typedef ObjectFactory<AbstractObject, IdentifierType, Args...> ThisClass;

  public:
    AbstractObject *create(const IdentifierType &id, Args... args) {
        typename ObjectMap::const_iterator i = this->objectmap_.find(id);

        if (this->objectmap_.end() != i) {
            return (i->second)(std::forward<Args>(args)...);
        }
        throw UnknownClass("Cannot create object of unregistered class.");
    }

    bool hasClass(const IdentifierType &id) {
        return this->objectmap_.find(id) != this->objectmap_.end();
    }

    bool registerClass(const IdentifierType &id,
                       ObjectCreator<AbstractObject, Args...> creator) {
        if (this->objectmap_.find(id) != this->objectmap_.end()) {
            throw DuplicateClass("Cannot register the same class twice.");
        }
        return this->objectmap_
            .insert(typename ObjectMap::value_type(id, creator))
            .second;
    }

    static ThisClass &instance() {
        static ThisClass factory;
        return factory;
    }

    std::vector<IdentifierType> listEntries() const {
        std::vector<IdentifierType> entries;
        for (auto imap : objectmap_) {
            entries.push_back(imap.first);
        }
        return entries;
    }

  private:
    typedef std::map<IdentifierType, ObjectCreator<AbstractObject, Args...>>
        ObjectMap;
    ObjectMap objectmap_;
};

template <typename Base, typename Derived, typename... Args>
Base *createInstance(Args &&...args) {
    return new Derived(std::forward<Args>(args)...);
}

} // namespace factory
