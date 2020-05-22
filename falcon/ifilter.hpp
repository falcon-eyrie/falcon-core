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

#ifndef IFILTER_HPP
#define IFILTER_HPP

#include "iprocessor.hpp"
#include <dsp/filter.hpp>

template <typename DATATYPE>
class IFilter : public IProcessor
{

public:
    virtual void Configure( const YAML::Node  & node, const GlobalContext& context) override;
    virtual void Prepare( GlobalContext& context ) override;
    virtual void Unprepare( GlobalContext& context ) override;
    virtual void CompleteStreamInfo( ) override;

protected:
    std::unique_ptr<dsp::filter::IFilter> filter_template_;
    std::vector<std::unique_ptr<dsp::filter::IFilter>> filters_;
    PortIn<DATATYPE>* data_in_port_;
    PortOut<DATATYPE>* data_out_port_;

};


#include "ifilter.ipp"

#endif // ifilter.hpp

