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

#include "streaminfo.hpp"

#include <utility>

bool IStreamInfo::finalized() const {
    return finalized_;
}

double IStreamInfo::stream_rate() const {
    return stream_rate_;
}

void IStreamInfo::set_stream_rate(double stream_rate) {
    if (finalized()) {
        throw std::runtime_error("Stream information is finalized. Cannot change stream rate.");
    }
    stream_rate_ = stream_rate;
}

void IStreamInfo::set_stream_rate(const IStreamInfo& info) {
    set_stream_rate(info.stream_rate());
}

void IStreamInfo::set_stream_name(const std::string& stream_name) {
    if (finalized()) {
        throw std::runtime_error("Stream information is finalized. Cannot change stream name.");
    }
    stream_name_ = stream_name;
}

void IStreamInfo::set_stream_name(const IStreamInfo& info) {
    set_stream_name(info.stream_name());
}

void IStreamInfo::set_stream_parameters(double stream_rate, const std::string& stream_name) {
    set_stream_name(stream_name);
    set_stream_rate(stream_rate);
}

void IStreamInfo::set_stream_parameters(const IStreamInfo& info) {
    set_stream_name(info.stream_name());
    set_stream_rate(info.stream_rate());
}

std::string IStreamInfo::datatype() const {
    return datatype_;
}
