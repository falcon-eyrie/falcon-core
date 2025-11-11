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

#include "zmqutil.hpp"
#include <string>

// Convert string to 0MQ string and send to socket
bool s_send(zmq::socket_t &socket, const std::string &string, int more) {
    // zmq::message_t message(string.size());
    zmq_msg_t message;
    zmq_msg_init_size(&message, string.size());

    memcpy(zmq_msg_data(&message), string.data(), string.size());
    std::size_t rc = zmq_msg_send(&message, socket, more);
    zmq_msg_close(&message);
    return rc == string.size();
}

bool s_send_multi(zmq::socket_t &socket, const zmq_frames &frames) {
    if (frames.empty())
        return true;

    // all frames but last one
    for (unsigned int i = 0; i < frames.size() - 1; ++i)
        if (!s_send(socket, frames[i], ZMQ_SNDMORE))
            return false;
    // last frame
    return s_send(socket, frames.back());
}

bool sockopt_rcvmore(zmq::socket_t &socket) {
    int64_t rcvmore = 0;
    size_t type_size = sizeof(int64_t);
    zmq_getsockopt(socket, ZMQ_RCVMORE, &rcvmore, &type_size);
    return rcvmore != 0;
}

// Receive 0MQ string from socket and convert into string
bool s_recv(zmq::socket_t &socket, std::string &s_message, int more) {
    zmq_msg_t message;
    zmq_msg_init(&message);
    int size = zmq_msg_recv(&message, socket, more);
    if (size == -1) {
        return false;
    }
    s_message.assign(static_cast<char *>(zmq_msg_data(&message)),
                     zmq_msg_size(&message));
    zmq_msg_close(&message);
    return true;
}

/*bool s_nonblocking_recv(zmq::socket_t &socket, std::string &s_message) {
  zmq_msg_t message;
  zmq_msg_init (&message);
  int size = zmq_msg_recv(&message, socket, ZMQ_DONTWAIT);
  if (size == -1) {
      return false;
  }
  s_message.assign(static_cast<char *>(zmq_msg_data(&message)),
zmq_msg_size(&message)); zmq_msg_close(&message); return true;
}*/
zmq_frames s_blocking_recv_multi(zmq::socket_t &socket) {
    zmq_frames frames;
    std::string message;
    do {
        s_recv(socket, message);
        frames.push_back(message);
        message.clear();
    } while (sockopt_rcvmore(socket));
    return frames;
}

bool s_nonblocking_recv_multi(zmq::socket_t &socket, zmq_frames &frames) {
    std::string message;
    do {
        if (!s_recv(socket, message, ZMQ_DONTWAIT)) {
            break;
        }
        frames.push_back(message);
        message.clear();
    } while (sockopt_rcvmore(socket));
    return !frames.empty();
}
