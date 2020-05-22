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
template <typename DATATYPE>
void IFilter<DATATYPE>::Configure( const YAML::Node & node, const GlobalContext& context ) {

    // load filter
    if (!node["filter"]) {
        throw ProcessingConfigureError( "No filter defined.", name() );
    }

    if (node["filter"]["file"]) {
        std::string f = context.resolve_path( node["filter"]["file"].as<std::string>(),
            "filters" );
        filter_template_.reset( dsp::filter::construct_from_file( f ) );
    } else {
        filter_template_.reset( dsp::filter::construct_from_yaml( node["filter"] ) );
    }
}

template <typename DATATYPE>
void IFilter<DATATYPE>::CompleteStreamInfo( ) {

    // check if we have the same number of input and output slots
    if (data_in_port_->number_of_slots() != data_out_port_->number_of_slots()) {
        auto err_msg = "Number of output slots (" +
            std::to_string( data_out_port_->number_of_slots() ) +
            ") on port '" + data_out_port_->name() +
            "' does not match number of input slots (" +
            std::to_string( data_in_port_->number_of_slots()) +
            ") on port '" + data_in_port_->name() + "'.";
        throw ProcessingStreamInfoError( err_msg, name() );
    }

    for (int k=0; k<data_in_port_->number_of_slots(); ++k) {
        data_out_port_->streaminfo(k).set_stream_rate( data_in_port_->streaminfo(k).stream_rate() );
        data_out_port_->streaminfo(k).set_parameters( data_in_port_->streaminfo(k).parameters() );
    }

}

template <typename DATATYPE>
void IFilter<DATATYPE>::Prepare( GlobalContext& context ) {

    // realize filter for each input slot, dependent on the number of channels upstream is sending
    filters_.clear();
    for (int k=0; k<data_in_port_->number_of_slots(); ++k ) {
        filters_.push_back( std::move(
            std::unique_ptr<dsp::filter::IFilter>( filter_template_->clone() ) ) );
        filters_.back()->realize( data_in_port_->streaminfo(k).parameters().nchannels );
    }
}

template <typename DATATYPE>
void IFilter<DATATYPE>::Unprepare( GlobalContext& context ) {

    // destroy realized filters
    filters_.clear();
}