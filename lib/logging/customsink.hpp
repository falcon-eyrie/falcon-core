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

#ifndef CUSTOM_SINK_H
#define CUSTOM_SINK_H

#include <deque>
#include <zmq.hpp>

#include "g3log/g3log.hpp"
#include "g3log/logmessage.hpp"

/**
 *  Custom logger sending message through network with zmq
 */
class ZMQSink {
   public:
    ZMQSink(zmq::context_t& context, int port);

    virtual ~ZMQSink();

    /**
     * Format the log message :
     *   all level : timestamp + level + message
     *   debug level : add file and line where the message have been emitted
     *   fatal level message are not send
     *
     * @param msg message format delivered by g3log lib
     * @return the new message format as a list of string
     */
    std::deque<std::string> FormatMessage(g3::LogMessage& msg);

    /**
     * Format the message + send through the network
     * @param msg message format delivered by g3log lib
     */
    void ReceiveLogMessage(g3::LogMessageMover message);

   private:
    zmq::socket_t* publisher;

    ZMQSink& operator=(const ZMQSink&) = delete;

    ZMQSink(const ZMQSink& other) = delete;
};

class ScreenSink {
   public:
    ScreenSink() { pthread_setname_np(pthread_self(), "G3LogScreenSink"); };

    virtual ~ScreenSink() {};

    // Linux xterm color
    // http://stackoverflow.com/questions/2616906/how-do-i-output-coloured-text-to-a-linux-terminal
    enum FG_Color { YELLOW = 33, RED = 31, GREEN = 32, WHITE = 97 };

    FG_Color GetColor(const LEVELS& level) const;

    /**
     * Format the log message :
     *   all level : timestamp + level + message
     *   debug level : add file and line where the message have been emitted
     *   fatal level message are not send
     *
     * note: same format as for zmq except it is wrote in one string instead of
     * a list of string
     *
     * @param msg message format delivered by g3log lib
     * @return the new message format as a string
     */
    std::string FormatMessage(const LEVELS& level, g3::LogMessage& msg);

    /**
     * Format the message + display on the screen
     * @param msg message format delivered by g3log lib
     */
    void ReceiveLogMessage(g3::LogMessageMover message);

   private:
    ScreenSink& operator=(const ScreenSink&) = delete;

    ScreenSink(const ScreenSink& other) = delete;
};

#endif