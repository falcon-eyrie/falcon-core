#pragma once
#include "disruptor/wait_strategy.h"
#include "utilities/math_numeric.hpp"
#include <string>
#include <zmq.hpp>

typedef uint16_t SlotType;
typedef Range<SlotType> SlotRange;
typedef disruptor::WaitStrategyOption WaitStrategy;

#include <string>

class PortAddress {
public:
  PortAddress(std::string processor, std::string port)
      : processor_name_(processor), port_name_(port), processor_class_("?"),
        port_datatype_("?") {}

  const std::string processor() const { return processor_name_; }
  const std::string port() const { return port_name_; }

  const std::string processor_class() const { return processor_class_; }
  const std::string port_datatype() const { return port_datatype_; }

  void set_port(std::string port, std::string port_datatype = "?") {
    port_name_ = port;
    port_datatype_ = port_datatype;
  }

  void set_processor_class(std::string klass) { processor_class_ = klass; }
  const std::string string(bool full = false) const{
    std::string s;

    if (full) {
      s = processor() + "[" + processor_class() + "]." + port() + "[" +
          port_datatype() + "]";
    } else {
      s = processor() + "." + port();
    }

    return s;
  };

protected:
  std::string processor_name_;
  std::string port_name_;
  std::string processor_class_;
  std::string port_datatype_;
};

class SlotAddress : public PortAddress {
public:
  SlotAddress(const PortAddress &port, int slot)
      : PortAddress(port), slot_(slot) {}

  int slot() const { return slot_; }

  void set_slot(int slot) { slot_ = slot; }

  const std::string string(bool full = false) const {
    auto s = PortAddress::string(full);
    s = s + "." + std::to_string(slot());
    return s;
  };

protected:
  int slot_;
};


class PortPolicy {
public:
  PortPolicy(SlotRange slot_number_range = SlotRange(1))
      : slot_number_range_(slot_number_range) {}
  SlotType min_slot_number() const { return slot_number_range_.lower(); }
  SlotType max_slot_number() const { return slot_number_range_.upper(); }
protected:
  SlotRange slot_number_range_;
};

class PortInPolicy : public PortPolicy {
public:
  PortInPolicy(SlotRange slot_number_range = SlotRange(1), bool cache = false,
               int64_t time_out = -1)
      : PortPolicy(slot_number_range), cache_enabled_(cache),
        time_out_(time_out) {}

  bool cache_enabled() const { return cache_enabled_; }
  int64_t time_out() const { return time_out_; }

protected:
  bool cache_enabled_; // input slot only
  int64_t time_out_;   // in microseconds, input slot only
};

class PortOutPolicy : public PortPolicy {
public:
  PortOutPolicy(SlotRange slot_number_range = SlotRange(1),
                int buffer_size = 200,
                WaitStrategy wait = WaitStrategy::kBlockingStrategy)
      : PortPolicy(slot_number_range), buffer_size_(buffer_size){}

  int buffer_size() const { return buffer_size_; }
  void set_buffer_size(int sz) { buffer_size_ = sz; }

protected:
  int buffer_size_;
};

class GlobalContext {
public:
  GlobalContext(){zmq_context_ = zmq::context_t(1);};
  GlobalContext(bool test_flag, const std::map<std::string, std::string> &uri)
      {zmq_context_ = zmq::context_t(1);};

    zmq::context_t &zmq() { return zmq_context_; }

    bool test() const { return false; }
    std::string resolve_path(const std::string &p,
                           std::string default_context) const {
    return "test/path";
  }
  private:
    zmq::context_t zmq_context_;
  };


class RunContext{
public:

  friend class IProcessor;

public:
  RunContext(GlobalContext &context): start_time_(Clock::now()), stop_time_(start_time_), global_context_(context){};
  RunContext(GlobalContext &context, std::atomic<bool> &terminate_signal,
             std::string run_group_id, std::string run_id,
             std::string template_id, bool test_flag)
      : start_time_(Clock::now()), stop_time_(start_time_), global_context_(context){}

  bool terminated() const { return false; }
  void Terminate() {}
  GlobalContext &global() { return global_context_; }
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

protected:
  TimePoint start_time_;
  TimePoint stop_time_;
  std::string error_message_;
  GlobalContext &global_context_;

};

class ProcessingContext{
public:
  ProcessingContext(RunContext &context, std::string processor_name, bool test)
      : run_context_(context){}

  RunContext &run() { return run_context_; }

  bool terminated() const { return run_context_.terminated(); }
  void Terminate() { run_context_.Terminate(); }
  std::string resolve_path(const std::string &p,
                           std::string default_context) const {
    return "test/path";
  }
  bool test() const { return false; }
private:
  RunContext &run_context_;

};
