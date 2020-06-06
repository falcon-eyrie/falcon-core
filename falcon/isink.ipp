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
//#include "isink.hpp"

template<typename DATATYPE>
inline void ISink<DATATYPE>::CreatePorts() {

    SetPortName();
    data_port_ = create_input_port<DATATYPE>(
            port_name,
            typename DATATYPE::Capabilities(),
            PortInPolicy( SlotRange(1) ) );

    CreateStates();
}

template<typename DATATYPE>
inline void ISink<DATATYPE>::Process( ProcessingContext& context ) {
    DATATYPE* data = nullptr;
    auto start = std::chrono::system_clock::now();
    if (!ProcessStart(context)){ return;};

    while (!context.terminated()) {

        if (!data_port_->slot(0)->RetrieveData(data)) {
            LOG(DEBUG) << name() << " : received finish signal while waiting for data!";
            break;
        }

        if (!ProcessData(context, data)){ break;};

        data_port_->slot(0)->ReleaseData();
    }

    auto end = std::chrono::system_clock::now();
    duration = end-start;
}
