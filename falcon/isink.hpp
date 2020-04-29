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

#ifndef ISINK_HPP
#define ISINK_HPP

#include "iprocessor.hpp"
#include <chrono>

template <typename DATATYPE>
class ISink : public IProcessor
{
private:
    virtual bool Process_loop( ProcessingContext& context ) {return true;} ;
    virtual bool Process_start( ProcessingContext& context ) {return true;};
    virtual void CreateStates() {};
    virtual void SetPortName() {port_name = "output";};

public:
    virtual void CreatePorts() override;
    virtual void Process( ProcessingContext& context ) override;

protected:
    PortIn<DATATYPE>* data_port_;
    DATATYPE* data;
    std::string port_name;
    std::chrono::duration<double>  duration;

};


#include "isink.ipp"

#endif // isink.hpp

