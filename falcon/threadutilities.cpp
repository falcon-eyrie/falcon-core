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

#include <unistd.h>

#include "threadutilities.hpp"

bool set_realtime_priority(pthread_t thread, ThreadPriority priority) {
    if (priority < PRIORITY_LOW) {
        return true;
    }

    double fraction = static_cast<double>(priority) / 100;
    if (fraction > 1) {
        fraction = 1.0;
    }

    auto priority_max = sched_get_priority_max(SCHED_FIFO);
    auto priority_min = sched_get_priority_min(SCHED_FIFO);

    // struct sched_param is used to store the scheduling priority
    struct sched_param params;
    // calculate priority value
    params.sched_priority =
        (int)(fraction * (priority_max - priority_min) + priority_min);

    // Attempt to set thread real-time priority to the SCHED_FIFO policy
    if (pthread_setschedparam(thread, SCHED_FIFO, &params) != 0) {
        return false;
    }

    // Now verify the change in thread priority
    int policy = 0;
    if (pthread_getschedparam(thread, &policy, &params) != 0) {
        return false;
    }

    // Check the correct policy was applied
    if (policy != SCHED_FIFO) {
        return false;
    }

    return true;
}

bool set_thread_core(pthread_t thread, ThreadCore core) {
    int num_cores = sysconf(_SC_NPROCESSORS_ONLN);

    if (core < 0) {
        return true;
    }

    if (core >= num_cores) {
        return false;
    }

    cpu_set_t cpuset;

    CPU_ZERO(&cpuset);

    CPU_SET(core, &cpuset);

    pthread_setaffinity_np(thread, sizeof(cpu_set_t), &cpuset);

    return true;
}
