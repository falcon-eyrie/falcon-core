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

#ifndef EXCEPTIONS_H
#define EXCEPTIONS_H

#include <exception>
#include <string>


class NotImplemented : public std::logic_error {
public:
    NotImplemented(const std::string & name) : std::logic_error(name + " has not been implemented.") { };
};

class InternalError : public std::logic_error {
public:
    InternalError(const std::string & context, const std::string & msg)
      : std::logic_error( "Internal error (" + context + "): " + msg ) {};
};

class DeviceError : public std::runtime_error { using std::runtime_error::runtime_error; };

class DeviceInterfaceError : public std::runtime_error { using std::runtime_error::runtime_error; };

class DeviceConfigureError : public std::runtime_error { using std::runtime_error::runtime_error; };

#endif
