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

#include <iostream>
#include <exception>
#include <regex>

#include "processorgraph.hpp"
#include "sharedstate.hpp"

#include "device_manager.hpp"
#include "device.hpp"

#include "utilities/general.hpp"

using namespace graph;

std::string graph_state_string( GraphState state ) {
    std::string s;
#define PROCESS_STATE(p) case(GraphState::p): s = #p; break;
    switch(state){
        PROCESS_STATE(NOGRAPH);
        PROCESS_STATE(CONSTRUCTING);
        PROCESS_STATE(PREPARING);
        PROCESS_STATE(READY);
        PROCESS_STATE(STARTING);
        PROCESS_STATE(PROCESSING);
        PROCESS_STATE(STOPPING);
        PROCESS_STATE(ERROR);
    }
#undef PROCESS_STATE
    return s;
}

std::vector<std::string> expandProcessorName( std::string s ) {
    
    std::vector<std::string> result;
    int startid, endid;
    
    // name# or name[#, #-#]
    std::regex re("(\\w+[a-zA-Z])((?:\\d+)|(?:\\([\\d,\\-]+\\)))?");
    std::smatch match;
    
    // remove all spaces
    s.erase( std::remove_if( s.begin(), s.end(), [](char x){ return std::isspace(x); } ), s.end() );
    
    // match regular expression
    if ( !std::regex_match(s, match, re) )
    { throw std::runtime_error("Invalid processor name: \"" + s + "\""); }
    
    //get base name
    if (!match[1].matched)
    { throw std::runtime_error("Invalid processor name (no base name): \"" + s + "\""); }
    std::string name = match[1].str();
    
    // parse part identifiers
    std::vector<int> identifiers;
    
    if (!match[2].matched) {
        result.push_back( name );
    } else {
        std::string piece = match[2].str();
        if (piece[0]=='(') {
            //match ID range vector
            //remove brackets and spaces
            piece.erase( std::remove_if( piece.begin(), piece.end(), [](char x){ return (x=='(' || x==')' || std::isspace(x)); } ), piece.end() );
            
            //split on comma
            auto id_pieces = split( piece, ',' );
            
            std::regex re_range("(\\d+)(?:\\-(\\d+))?");
            std::smatch match_range;
            
            //match start and end id of ranges
            for (const auto &q : id_pieces)
            {
                if (std::regex_match(q, match_range, re_range)) {
                    startid = stoi( match_range[1].str() );
                    if (match_range[2].matched) { endid = stoi( match_range[2].str() ); }
                    else { endid = startid; }
                    for (auto kk = startid; kk<=endid; kk++ )
                    { result.push_back( name + std::to_string(kk) ); }
                } else { throw std::runtime_error("Invalid processor name (invalid identifiers): \"" + s + "\""); }
            }
        } else {
            //try to convert to int
            try {
                result.push_back( name + std::to_string( stoi( piece ) ) );
            } catch ( std::invalid_argument &e )
            { throw std::runtime_error("Invalid processor name (invalid identifiers): \"" + s + "\""); }
        }
    }
    
    return result;
    
}

void ProcessorGraph::ConstructProcessorEngines( const YAML::Node& node ) {
    
    std::vector<std::string> processor_name_list;
    std::string processor_name;
    std::string processor_class;
    std::unique_ptr<IProcessor> processor;

    // loop through all processors defined in YAML document
    for(YAML::const_iterator it=node.begin();it!=node.end();++it) {
        // expand processor name
        // e.g. name -> name, name1 -> name1, name(1-2, 4) -> name1, name2, name4
        processor_name_list = expandProcessorName( it->first.as<std::string>() );
        
        // get processor definition
        YAML::Node processor_node = it->second;
        
        if (processor_node["class"]) {
            processor_class = processor_node["class"].as<std::string>();
            
            // loop through expanded name list
            for (auto &name_it : processor_name_list ) {
                
                processor_name = name_it;
                
                // does processor already exist?
                auto it2 = processors_.find( processor_name );
                
                if ( it2 == processors_.end() ) { // no processor with this name known
                    
                    try {
                        processor.reset( ProcessorFactory::instance().create( processor_class ) );
                    } catch ( factory::UnknownClass& e ) {
                        throw InvalidProcessorError( "Cannot create processor " + processor_name + " of unknown class " + processor_class + "." );
                    }
                    
                    processor->set_name_and_type( processor_name,  processor_class);
                    
                    processor->internal_Configure( processor_node, global_context_ );
                    
                    processors_[processor_name]= std::make_pair( processor_class, std::move(processor) );
                    
                    LOG(DEBUG) << "Constructed and configured " << processor_name << " (" << processor_class << ").";
                    
                } else if ( it2->second.first == processor_class ) { // processor with this name and class found
                    
                    it2->second.second->internal_Configure( processor_node, global_context_ );
                    
                    LOG(DEBUG) << "Configured processor " << processor_name << " (" << processor_class << ")";
                    
                } else { // processor with this name, but different class found
                    throw InvalidProcessorError( "Processor " + processor_name + " of different class (" + it2->second.first + ") already exists." );
                }
            }
                
        } else {
            throw InvalidProcessorError( "No class specified for processor " + processor_name + ".");
        }
    }
}

void ParseConnectionRules( const YAML::Node& node, StreamConnections& connections ) {
    
    for(YAML::const_iterator it=node.begin();it!=node.end();++it) {
        expandConnectionRule( parseConnectionRule( it->as<std::string>() ), connections );
        LOG(DEBUG) << "Parsed connection rule " << it->as<std::string>();
    }
}

ProcessorGraph::ProcessorGraph( GlobalContext& context ) : global_context_(context), terminate_signal_(false) {
    
    // log list of registered processors
    std::vector<std::string> processors = ProcessorFactory::instance().listEntries();
    for (auto item : processors ) {
        LOG(INFO) << "Registered processor " << item;
    }
    
    std::vector<std::string> device_list = device::DeviceFactory::instance().listEntries();
    for (auto item : device_list ) {
        LOG(INFO) << "Registered device " << item;
    }
}

std::string ProcessorGraph::state_string() const {
    
    return graph_state_string( state_ );
}

IProcessor* ProcessorGraph::LookUpProcessor(std::string name) {
    if (processors_.count( name )==0) {
        throw InvalidProcessorError(
            "Processor \"" + name + "\" not found.");
    }
    
    return processors_[name].second.get();
}

std::vector<std::pair<std::string, std::shared_ptr<IState>>> ProcessorGraph::LookUpStates(std::vector<std::string> state_addresses) {
    
    std::vector<std::pair<std::string, std::shared_ptr<IState>>> states;
    
    for (auto & state_address : state_addresses){
        // parse processor.state name
        std::vector<std::string> address = split(state_address, '.');
        
        if (address.size()!=2) {
            throw InvalidGraphError("Error parsing state address \"" +
                state_address + "\"" );
        }
        
        // expand processor part of address
        auto expanded_processor = expandProcessorName( address[0] );
    
        for (auto & itv : expanded_processor) {          
            
            IProcessor* processor = LookUpProcessor(itv);
            auto state = processor->shared_state(address[1]);  // fix error message when this fails
            
            states.push_back( std::make_pair( itv + "." + address[1], state ) );
        }
    }
    
    return states;
}

void ProcessorGraph::BuildSharedStates( const YAML::Node& node ) {
    
    // states:
    //     - [processor.state, processor.state, ...]
    //     - group-name:
    //         permission: xxx
    //         description: xxx
    //         states: [...]
    //     - group-name: [...]

    std::vector<std::pair<std::string, std::shared_ptr<IState>>> states;
    std::string alias;
    Permission permission;
    std::string description;
    int group_index = 0;
    
    // loop through items in sequence:
    for(YAML::const_iterator link=node.begin();link!=node.end();++link) {
        
        ++group_index;
        
        description = "";
        permission = Permission::WRITE;
        
        if (link->IsSequence()) {
            alias = "alias_" + std::to_string(group_index);
            states = LookUpStates(link->as<std::vector<std::string>>());
        } else if (link->IsMap() && link->size()==1 && link->begin()->second.IsSequence()) {
            alias = link->begin()->first.as<std::string>();
            states = LookUpStates(link->begin()->second.as<std::vector<std::string>>());
        } else if (link->IsMap() && link->size()==1 && link->begin()->second.IsMap()) {
            alias = link->begin()->first.as<std::string>();
            description = link->begin()->second["description"].as<std::string>("");
            permission = permission_from_string(link->begin()->second["permission"].as<std::string>("unspecified"));
            states = LookUpStates(link->begin()->second["states"].as<std::vector<std::string>>());
        } else {
            throw InvalidGraphError("Error parsing linked state request.");
        }
        
        shared_state_map_.AddAlias(alias, permission, description);
        for (auto const & state : states) {
            shared_state_map_.ShareState(alias, state.first, state.second);
            LOG(DEBUG) << "Successfully linked state " << state.first << " to alias " << alias;
        }
    }
}

void ProcessorGraph::CreateConnection( SlotAddress & out, SlotAddress & in ) {
    
    // get ProcessorEngine for output and input
    IProcessor *processor_out, *processor_in;
    try {
        processor_out = this->processors_.at( out.processor() ).second.get();
    } catch (std::out_of_range& e) {
        throw std::out_of_range( "Unknown processor \"" + out.processor() + "\"" );
    }
    
    out.set_processor_class(processor_out->type());

    try {
        processor_in = this->processors_.at( in.processor() ).second.get();
    } catch (std::out_of_range& e) {
        throw std::out_of_range( "Unknown processor \"" + in.processor() + "\"" );
    }
    
    in.set_processor_class(processor_in->type());

    // let engine prepare connections ( get default port, check port, reserve slot, update address )
    processor_out->internal_PrepareConnectionOut( out );
    processor_in->internal_PrepareConnectionIn( in );
    
    // check compatibility
    processor_in->internal_ConnectionCompatibilityCheck( in, processor_out, out );
    
    // connect in to out, connect out to in
    processor_in->internal_ConnectIn( in, processor_out, out );
    
    try {
        processor_out->internal_ConnectOut( out, processor_in, in );
    } catch (...) {
        // internal error
        //in_connector_->Disconnect();
        throw std::runtime_error( "Internal error: cannot connect to output slot" );
    }

}

void ProcessorGraph::ConstructDevices( const YAML::Node& node ) {
    // devices:
    //   <ID>:
    //     type: <type>
    //     address: <address>
    //     options: { }
    //     adapters: { }
    
    // loop through all devices
    for(YAML::const_iterator it=node.begin();it!=node.end();++it) {
        
        // get device ID
        std::string id = it->first.as<std::string>();
        
        // it->second should be a map with type
        if (!it->second.IsMap() || !it->second["type"]) {
            throw InvalidGraphError("Incomplete device description (" + id + ")");
        }
        
        std::string device_type = it->second["type"].as<std::string>();
        
        std::string address = "";
        if (it->second["address"]) {
            address = it->second["address"].as<std::string>();
        }
        
        // now let's construct the device and add it to the pool
        device::DeviceManager::instance().AddDevice(id, device_type, address,
            it->second["options"], it->second["adapters"] ? it->second["adapters"] : YAML::Node());
        
        auto dev = device::DeviceManager::instance().DeviceByID(id);
        
        LOG(INFO) << "Device created: " << dev->to_string();
        
        auto adapters = dev->adapters();
        auto interfaces = dev->interfaces();
        
        if (adapters.empty() && interfaces.empty()) {
            LOG(INFO) << "Device has no adapters installed and does not support any interfaces.";
        } else {
            LOG_IF(INFO, !adapters.empty()) << "installed adapters: " << join(adapters.cbegin(), adapters.cend(), std::string(", "));
            LOG_IF(INFO, !interfaces.empty()) << "supported interfaces: " << join(interfaces.cbegin(), interfaces.cend(), std::string(", "));
        }
    }
    
}

void ProcessorGraph::Build( const YAML::Node& node ) {
    
    if (state_!=GraphState::NOGRAPH) {
        throw InvalidStateError("A graph has already been built. Destroy old graph first.");
    }
    
    if (!node["processors"] || !node["processors"].IsMap()) {
        throw InvalidGraphError("No processors found in graph definition.");
    }
    
    set_state( GraphState::CONSTRUCTING );
    
    if (node["devices"] && node["devices"].IsMap()) {
        try {
            ConstructDevices( node["devices"] );
            LOG(INFO) << "Constructed and configured all devices";
        } catch (...) {
            Destroy();
            throw;
        }
    }
    
    try {
        
        ConstructProcessorEngines( node["processors"] );
        LOG(INFO) << "Constructed and configured all processors";
        
        for (auto &it : this->processors_) {
            it.second.second->internal_CreatePorts();
            LOG(DEBUG) << "Created ports for processor " << it.first;
        }
        LOG(INFO) << "All ports have been created.";
        
        if (node["connections"] && node["connections"].IsSequence()) {
            
            ParseConnectionRules( node["connections"], connections_ );
            LOG(INFO) << "Parsed all connection rules.";
            
            for ( auto &it : connections_ ) {
                CreateConnection( it.first, it.second );
                LOG(DEBUG) << "Established connection " << it.first.string(true) << "->" << it.second.string(true);
            }
            LOG(INFO) << "All connections have been established.";
        }
        
        if (node["states"] && node["states"].IsSequence()) {
            BuildSharedStates( node["states"] );
            LOG(INFO) << "Linked all shared states.";
        }
        
    } catch (...) {
        Destroy();
        throw;
    }
    
    
    try {
        // negiotiate connections
        for (auto &it : this->processors_) {
            it.second.second->internal_NegotiateConnections();
            LOG(DEBUG) << "Negotiated data streams for processor " << it.first;
        }
        LOG(INFO) << "All data streams have been negotiated.";
        
        // build ringbuffers
        for (auto &it : this->processors_) {
            it.second.second->internal_CreateRingBuffers();
            LOG(DEBUG) << "Constructed ring buffer for processor " << it.first;
        }
        
    } catch(...) {
        Destroy();
        throw;
    }
    
    set_state( GraphState::PREPARING );
    
    // prepare processors
    try {
        for (auto &it : this->processors_) {
            it.second.second->Prepare(global_context_);
            LOG(DEBUG) << "Successfully prepared processor " << it.first;
        }
        LOG(INFO) << "All processors have been prepared.";
    } catch ( ... ) {
        
        Destroy();
        throw;
    }
    
    yaml_ = node;
    
    LOG(INFO) << "Graph was successfully constructed.";
    
    set_state(GraphState::READY);
}

void ProcessorGraph::Destroy() {
    
    // can only destroy graph if state is CONSTRUCTING, PREPARING or READY
    if (state_==GraphState::PROCESSING || state_==GraphState::STARTING || state_==GraphState::STOPPING) {
        throw InvalidStateError("Cannot destroy graph while processing.");
    } else if (state_==GraphState::NOGRAPH) {
        // nothing to destroy
        return;
    }
    
    if (state_!=GraphState::CONSTRUCTING) {
        try {
            // unprepare processors
            for (auto &it : this->processors_) {
                it.second.second->Unprepare(global_context_);
                LOG(DEBUG) << "Successfully unprepared processor " << it.first;
            }
        } catch (...) {
            connections_.clear();
            processors_.clear();
            set_state(GraphState::NOGRAPH);
            throw InvalidGraphError("Error while unpreparing processors. Forced destruction of graph. Possible corruption of internal state.");
        }
    }
    
    // destroy connections and processors
    shared_state_map_.clear();  // will unlink all states and remove groups
    connections_.clear();
    processors_.clear();  // will destroy processors and all their ports/states
    
    yaml_ = YAML::Null;
    
    LOG(INFO) << "Graph has been destroyed.";
    
    set_state(GraphState::NOGRAPH);
}

void ProcessorGraph::StartProcessing( std::string run_group_id, std::string run_id, std::string template_id, bool test_flag ) {
    
    // start processing only if state is READY
    
    if (state_ == GraphState::READY ) {
        
        // construct RunInfo object
        //runinfo_.reset( new RunInfo( terminate_signal_, context_, run_identifier, destination, source ) );
        run_context_.reset( new RunContext( global_context_, terminate_signal_, run_group_id, run_id, template_id, test_flag ) );
        
        set_state(GraphState::STARTING);
        
        // prepare all processors for processing
        // (i.e. flush buffers)
        for ( auto& it : this->processors_ ) {
            it.second.second->internal_PrepareProcessing();
            LOG(DEBUG) << "Prepared data stream ports of processor " << it.first;    
        }
        LOG(INFO) << "Prepared all data stream ports for processing.";
        
        try {
            //loop through all processors
            for ( auto& it : this->processors_ ) {
                it.second.second->internal_Start(*run_context_);
                LOG(DEBUG) << "Started thread for processor " << it.first;
            }
            LOG(INFO) << "Started all processors.";
        } catch( ... ) {
            StopProcessing();
            throw;
        }
        
        //wait until all processors are in running state
        while (!all_processors_running()) {
            if (run_context_->terminated()) {
                // processor terminated during preparation or preprocessing
                // other processors need to be unlocked still
                break;
            }
        }
        
        // all processors have either passed the preprocessing step
        // or have terminated with error, which will be dealt with in graphmanager::run
        // let's signal everyone to GO
        {
            std::unique_lock<std::mutex> lock(run_context_->mutex);
            run_context_->go_signal = true;
            run_context_->go_condition.notify_all();
        }
        
        set_state(GraphState::PROCESSING);
        
    } else if (state_ == GraphState::NOGRAPH || state_ == GraphState::CONSTRUCTING || state_ == GraphState::PREPARING) {
        throw InvalidStateError("Graph is not yet assembled.");
    } else { // STARTING, STOPPING
        // pass
    }
}

void ProcessorGraph::StopProcessing( ) {
   
    if (state_ == GraphState::PROCESSING || state_ == GraphState::STARTING)
    {
        set_state(GraphState::STOPPING);
        
        if (run_context_->error()) {
            LOG(ERROR) << "Processing terminated with error. " << run_context_->error_message();
        }
        
        // signal stop
        run_context_->Terminate();
        
        // alert waiting processors
        for ( auto& it : this->processors_ ) {
            it.second.second->internal_Alert();
        }
        // join processor threads
        for ( auto& it : this->processors_ ) {
            it.second.second->internal_Stop();
        }
        
        LOG(INFO) << "Stopped all processors.";
        LOG(INFO) << "Graph was processing for " << std::to_string( run_context_->seconds() ) << " seconds";
        
        run_context_.reset();
        terminate_signal_.store(false);
        
        set_state(GraphState::READY);
        
    } else if (state_ == GraphState::NOGRAPH || state_ == GraphState::CONSTRUCTING || state_ == GraphState::PREPARING) {
        throw InvalidStateError("Graph is not yet assembled.");
    } else { // READY, STOPPING 
        // pass
    }
    
}

void ProcessorGraph::Update( YAML::Node& node ) {
    
    // YAML
    // shared-state: value
    // processor: {state: value}
    
    // make sure node is a map
    if (!node.IsMap()) {
        throw InvalidProcessorError("No valid map with states found.");
    }
    
    // loop through all keys
    for(YAML::iterator it=node.begin();it!=node.end();++it) {
        
        std::string key = it->first.as<std::string>();
        
        if (it->second.IsMap()){
            // find corresponding processor engine
            if (processors_.count( key )==0) {
                LOG(ERROR) << "No processor named " << key;
                continue;
            }
            
            IProcessor* processor = processors_[key].second.get();
            
            // loop through states
            for (YAML::iterator it2=it->second.begin();it2!=it->second.end();++it2) {
                try {
                    auto state_name = it2->first.as<std::string>();
                    auto state_value = it2->second.as<std::string>();
                    //it2->second = processor->internal_UpdateState( state_name, state_value );
                    auto pstate = processor->shared_state(state_name);
                    
                    // check if externally settable??
                    if (pstate->external_permission() == Permission::WRITE) {
                        // set from string
                        it2->second = pstate->set_string( state_value );
                    } else {
                        throw std::runtime_error( "Shared state " + state_name + " on processor " + key + " can not be controlled externally.");
                    }
                    LOG(UPDATE) << "State " << key << "." << state_name << " set to " << state_value;
                } catch ( std::exception & e ) {
                    it2->second = false;
                    LOG(ERROR) << "Unable to update state value: " << e.what();
                }
            }
        } else {  // key points to shared state alias
            try {
                auto state_value = it->second.as<std::string>();
                it->second = shared_state_map_.UpdateAlias(key, state_value);
                LOG(UPDATE) << "Alias state " << key << " set to " << state_value;
            } catch (std::exception & e) {
                it->second = false;
                LOG(ERROR) << "Unable to update state value: " << e.what();
            }
        }
    }
}

void ProcessorGraph::Retrieve( YAML::Node& node ) {
    
    // YAML
    // processor:
    //    state: <null>
    
    // make sure node is a map
    if (!node.IsMap()) {
        throw InvalidProcessorError("No valid map with states found.");
    }
    
    // loop through all keys
    for(YAML::iterator it=node.begin();it!=node.end();++it) {
        
        std::string key = it->first.as<std::string>();
        
        if (it->second.IsMap()){
            // find corresponding processor engine
            if (processors_.count( key )==0) {
                LOG(ERROR) << "No processor named " << key;
                continue;
            }
            
            IProcessor* processor = processors_[key].second.get();
            
            // loop through states
            for (YAML::iterator it2=it->second.begin();it2!=it->second.end();++it2) {
                try {
                    auto state_name = it2->first.as<std::string>();
                    //it2->second = processor->internal_RetrieveState( state_name );
                    auto pstate = processor->shared_state(state_name);
                    if (pstate->external_permission() != Permission::NONE) {
                        it2->second = pstate->get_string();
                    } else {
                        throw std::runtime_error( "Shared state " + state_name + " on processor " + key + " can not be read externally.");
                    }
                } catch ( std::exception & e ) {
                    it2->second = YAML::Null;
                    LOG(ERROR) << "Unable to retrieve state value: " << e.what();
                }
            }
        } else {  // key points to shared state alias
            try {
                it->second = shared_state_map_.RetrieveAlias(key);
            } catch (std::exception & e) {
                it->second = YAML::Null;
                LOG(ERROR) << "Unable to retrieve state value: " << e.what();
            }
        }
    }
}

void ProcessorGraph::Apply( YAML::Node& node ) {
   
    // YAML
    // processor:
    //     method:
    //         parameter: value
    
    if (!node.IsMap()) {
        throw InvalidProcessorError("No processors found in method definition.");
    }
    // loop through all processors, make sure value is another map
    for(YAML::iterator it=node.begin();it!=node.end();++it) {
        std::string processor_name = it->first.as<std::string>();
        
        if (!it->second.IsMap()) { 
            LOG(ERROR) << "Invalid method definition for processor " << processor_name;
            continue;
        }
        // find corresponding processor engine
        if (processors_.count( processor_name )==0) {
            LOG(ERROR) << "In method definition: no processor named " << processor_name;
            continue;
        }
        
        IProcessor* processor = processors_[processor_name].second.get();
        
        // loop through all states
        for (YAML::iterator it2=it->second.begin();it2!=it->second.end();++it2) {
            try {
                it2->second = processor->internal_ApplyMethod( it2->first.as<std::string>(), it2->second );
            } catch ( std::exception & e ) {
                it2->second = YAML::Null;
                LOG(ERROR) << "Unable to apply method: " << e.what();
            }
        }
    }
}

std::string ProcessorGraph::ExportYAML() {
    
    std::string s="";
    YAML::Node node;
    YAML::Emitter out;
    
    if (state_!=GraphState::NOGRAPH) {
    
        for ( auto& it : this->processors_ ) {
            node["processors"][it.first] = it.second.second->ExportYAML();
            node["processors"][it.first]["class"] = it.second.first;
            
            if (yaml_["processors"][it.first]["options"]) {
                node["processors"][it.first]["options"] = yaml_["processors"][it.first]["options"];
            }
            
            if (yaml_["processors"][it.first]["advanced"]) {
                node["processors"][it.first]["advanced"] = yaml_["processors"][it.first]["advanced"];
            }
            
        }
        
        for (auto& it : this->connections_ ) {
            node["connections"].push_back( it.first.string() + "=" + it.second.string() );
        }
        
        node["states"] = shared_state_map_.ExportYAML();
        
        if (yaml_["devices"]) {
            node["devices"] = yaml_["devices"];
        }
        
        out << node;
        s = out.c_str();
    }
    
    return s;
    
}


