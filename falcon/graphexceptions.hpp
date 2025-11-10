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
#include <string>

class GraphException : public std::runtime_error {
  public:
    GraphException(std::string const &error, std::string const &source = "")
        : std::runtime_error(source == "" ? error : source + ": " + error) {}
    virtual std::string gettype() const { return std::string("None"); }
    virtual bool isFatal() const { return true; }
};

#define GRAPHEXCEPTION(TYPE, FATAL)                                            \
    class TYPE : public GraphException {                                       \
      public:                                                                  \
        TYPE(std::string const &error, std::string const &source = "")         \
            : GraphException(error, source) {}                                 \
                                                                               \
      public:                                                                  \
        std::string gettype() const { return std::string(#TYPE); }             \
                                                                               \
      public:                                                                  \
        bool isFatal() const { return FATAL; }                                 \
    }

#define GRAPHERROR(TYPE) GRAPHEXCEPTION(TYPE, true)
#define GRAPHWARNING(TYPE) GRAPHEXCEPTION(TYPE, false)

GRAPHERROR(NoGraphError);
GRAPHERROR(InvalidGraphError);
GRAPHERROR(InvalidStateError);
GRAPHERROR(InvalidProcessorError);
GRAPHERROR(InvalidGraphCommandError);

GRAPHWARNING(BadGraphDefinition);
