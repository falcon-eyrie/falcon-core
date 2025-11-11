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
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstdio>
#include <ctime>
#include <map>
#include <mutex>
#include <string>

#include "context.hpp"
#include "logging/log.hpp"
#include "utilities/time.hpp"

// forward declaration
namespace graph {
class ProcessorGraph;
}

class RunContext : public StorageContext {
  public:
    friend class graph::ProcessorGraph;
    friend class IProcessor;

  public:
    RunContext(GlobalContext &context, std::atomic<bool> &terminate_signal,
               std::string run_group_id, std::string run_id,
               std::string template_id, bool test_flag)
        : StorageContext(context), global_context_(context),
          start_time_(Clock::now()), stop_time_(start_time_),
          terminate_signal_(terminate_signal), template_id_(template_id),
          default_test_flag_(test_flag) {
        struct stat info;

        // use default run group id if none given
        run_group_id_ = run_group_id.empty() ? "default" : run_group_id;

        // add run group storage site
        add_storage_context("rungroup",
                            storage_context("runroot") + "/" + run_group_id_);

        if (!template_id.empty()) {
            add_storage_context("templatebase", storage_context("rungroup") +
                                                    "/" + template_id);
            if ((stat(storage_context("templatebase").c_str(), &info) < 0) ||
                !(info.st_mode & S_IFDIR)) {
                throw std::runtime_error(
                    "Run source folder does not exist or is not accessible. (" +
                    storage_context("templatebase") + ")");
            }
        }

        // create run group folder
        if (mkdir(storage_context("rungroup").c_str(),
                  S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH) != 0) {
            if (errno != EEXIST) {
                throw std::runtime_error("Cannot create run environment " +
                                         storage_context("rungroup"));
            }
        }

        // generate default destination
        if (run_id.empty()) {
            char buffer[20];

            time_t rawtime;
            struct tm *timeinfo;

            time(&rawtime);
            timeinfo = localtime(&rawtime);

            strftime(buffer, 20, "%Y%m%d_%H%M%S", timeinfo);

            run_id = buffer;
        }

        add_storage_context("runbase",
                            storage_context("rungroup") + "/" + run_id);
        run_id_ = run_id;

        // create run destination folder
        if (mkdir(storage_context("runbase").c_str(),
                  S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH) != 0) {
            if (errno == EEXIST) {
                throw std::runtime_error("Run base folder already exists. (" +
                                         storage_context("runbase") + ")");
            } else {
                throw std::runtime_error("Cannot create run base folder " +
                                         storage_context("runbase"));
            }
        }

        // create symbolic link rungroup/_last_run pointing to run base folder
        std::string symlinkname = storage_context("rungroup") + "/_last_run";
        // remove old symlink (if present)
        std::remove(symlinkname.c_str());
        // create new symlink
        if (symlink(storage_context("runbase").c_str(), symlinkname.c_str()) !=
            0) {
            LOG(WARNING) << "Could not create symbolic link for last run.";
        }

        // create symbolic link runroot/_last_run_group pointing to run group
        // folder
        symlinkname = storage_context("runroot") + "/_last_run_group";
        // remove old symlink (if present)
        std::remove(symlinkname.c_str());
        // create new symlink
        if (symlink(storage_context("rungroup").c_str(), symlinkname.c_str()) !=
            0) {
            LOG(WARNING)
                << "Could not create symbolic link for last run group.";
        }

        add_storage_context("lastrunbase",
                            storage_context("rungroup") + "/_last_run");
        add_storage_context("lastrungroup",
                            storage_context("runroot") + "/_last_run_group");

        set_default_context("runbase");
    }

    GlobalContext &global() { return global_context_; }

    bool terminated() const { return terminate_signal_.load(); }

    void Terminate() {
        if (!terminate_signal_.exchange(true)) {
            stop_time_ = Clock::now();
        }
    }
    void TerminateWithError(std::string processor_name, std::string step,
                            std::string error_message) {
        if (!terminate_signal_.exchange(true)) {
            stop_time_ = Clock::now();
            error_message_ = "Processor `" + processor_name + "` failed in `" +
                             step + "`: " + error_message;
        }
    }

    TimePoint start_time() const { return start_time_; }
    TimePoint stop_time() const {
        if (terminated()) {
            return stop_time_;
        } else {
            return Clock::now();
        }
    }
    int minutes() const {
        return (std::chrono::duration_cast<std::chrono::minutes>(stop_time() -
                                                                 start_time())
                    .count());
    }
    int seconds() const {
        return (std::chrono::duration_cast<std::chrono::seconds>(stop_time() -
                                                                 start_time())
                    .count());
    }

    std::string error_message() {
        if (terminated()) {
            return error_message_;
        } else {
            return "";
        }
    }
    bool error() {
        if (terminated()) {
            return error_message_.size() > 0;
        } else {
            return false;
        }
    }

    std::string run_group_id() const { return run_group_id_; }
    std::string run_id() const { return run_id_; }
    std::string template_id() const { return template_id_; }

    bool test() const { return default_test_flag_.load(); }

  protected:
    std::mutex mutex;
    std::condition_variable go_condition;
    bool go_signal = false;

  private:
    GlobalContext &global_context_;

  protected:
    TimePoint start_time_;
    TimePoint stop_time_;
    std::atomic<bool> &terminate_signal_;
    std::string error_message_;

  private:
    std::string run_group_id_;
    std::string run_id_;
    std::string template_id_;
    std::atomic<bool> default_test_flag_;
};

class ProcessingContext : public StorageContext {
  public:
    ProcessingContext(RunContext &context, std::string processor_name,
                      bool test)
        : StorageContext(context), run_context_(context),
          processor_name_(processor_name), test_flag_(test) {
        add_storage_context("run",
                            storage_context("runbase") + "/" + processor_name);
        if (mkdir(storage_context("run").c_str(),
                  S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH) != 0) {
            if (errno != EEXIST) {
                throw std::runtime_error(
                    "Cannot create processor run environment " +
                    storage_context("run"));
            }
        }

        if (storage_map().count("templatebase") == 1) {
            add_storage_context("template", storage_context("templatebase") +
                                                "/" + processor_name);
        }

        // add processor specific test storage site
        if (test) {
            add_storage_context("test", storage_context("run") + "/test");
            if (mkdir(storage_context("test").c_str(),
                      S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH) != 0) {
                if (errno != EEXIST) {
                    throw std::runtime_error(
                        "Cannot create processor test environment " +
                        storage_context("test"));
                }
            }

            if (storage_map().count("template") == 1) {
                add_storage_context("templatetest",
                                    storage_context("template") + "/test");
            }
        }

        add_storage_context("lastrun", storage_context("lastrunbase") + "/" +
                                           processor_name);
        add_storage_context("lasttest", storage_context("lastrun") + "/test");
        set_default_context("run");
    }

    RunContext &run() { return run_context_; }

    bool test() const { return test_flag_.load(); }

    bool terminated() const { return run_context_.terminated(); }
    void Terminate() { run_context_.Terminate(); }
    void TerminateWithError(std::string step, std::string error_message) {
        run_context_.TerminateWithError(processor_name_, step, error_message);
    }

  private:
    RunContext &run_context_;
    std::string processor_name_;
    std::atomic<bool> test_flag_;
    std::map<std::string, std::string> storage_map_;
};
