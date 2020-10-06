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

#include <memory>
#include <set>
#include <string>
#include <vector>

#include "t_istreamports.hpp"
#include "utilities/math_numeric.hpp"


// forward declarations

template <typename DATATYPE> class SlotIn;
template <typename DATATYPE> class PortOut;
template <typename DATATYPE> class PortIn;

template <typename DATATYPE> class SlotOut : public ISlotOut {
  friend class PortOut<DATATYPE>;

public:
  SlotOut(PortOut<DATATYPE> *parent, const SlotAddress &address,
          const typename DATATYPE::Parameters &parameters)
      : ISlotOut(parent, address), streaminfo_(parameters),
        ringbuffer_serial_number_(0) {}

  typename DATATYPE::Data *ClaimData(bool clear);
  void PublishData(){};
  std::deque<typename DATATYPE::Data *> getData(){return fake_data;};
  virtual StreamInfo<DATATYPE> &streaminfo() { return streaminfo_; }
  uint64_t nitems_produced() const;

public:
  StreamInfo<DATATYPE> streaminfo_;


protected:
  uint64_t ringbuffer_serial_number_;

public:
  std::deque<typename DATATYPE::Data *> fake_data;
};

template <typename DATATYPE> class PortOut : public IPortOut {
public:
  PortOut(IProcessor *parent, const PortAddress &address,
          const typename DATATYPE::Capabilities &capabilities,
          const typename DATATYPE::Parameters &parameters,
          const PortOutPolicy &policy)
      : IPortOut(parent, address, policy),
        parameters_(parameters) {
    NewSlot(policy.min_slot_number());
  }

  SlotType number_of_slots() const { return slots_.size(); }
  std::string datatype() const { return DATATYPE::datatype(); }

  StreamInfo<DATATYPE> &streaminfo(std::size_t index) {
    return slots_[index]->streaminfo();
  }

  virtual SlotOut<DATATYPE> *slot(std::size_t index) {
    return slots_[index].get();
  }

  SlotOut<DATATYPE> *dataslot(std::size_t index) { return slots_[index].get(); }
  std::string name() const {  return "tests"; }

protected:
  void NewSlot(int n = 1);

private:
  typename DATATYPE::Parameters parameters_; // default parameters
  std::vector<std::unique_ptr<SlotOut<DATATYPE>>> slots_;
};

template <typename DATATYPE> class SlotIn : public ISlotIn {
  friend class PortIn<DATATYPE>;

public:
  SlotIn(PortIn<DATATYPE> *parent, const SlotAddress &address,
         typename DATATYPE::Capabilities capabilities, int64_t time_out = -1,
         bool cache = false)
      : ISlotIn(parent, address, time_out, cache), fake_data(std::deque<typename DATATYPE::Data *>()){
  }

  void SetFakeData( std::deque<typename DATATYPE::Data*> &data) {
    fake_data=data;
  }
  void SetFakeDelay( std::deque<long int> &delay) {
    fake_delay=delay;

  }

  const typename DATATYPE::Data *GetDataPrototype() const;
  bool RetrieveData(typename DATATYPE::Data *&data);
  bool RetrieveDataAll(std::vector<typename DATATYPE::Data *> &data);

  const StreamInfo<DATATYPE> &streaminfo() {
    return (StreamInfo<DATATYPE> &)upstream_->streaminfo();
  }

  uint64_t status_read() const { return 1; }

private:
  std::deque<typename DATATYPE::Data *> fake_data;
  std::deque<long int> fake_delay;

};

template <typename DATATYPE> class PortIn : public IPortIn {
  friend IProcessor;
public:
  PortIn(IProcessor *parent, const PortAddress &address,
         const typename DATATYPE::Capabilities &capabilities,
         const PortInPolicy &policy)
      : IPortIn(parent, address, policy), capabilities_(capabilities), max_slots_(policy.max_slot_number()) {
    NewSlot(policy.min_slot_number());
  }

  SlotType number_of_slots() const override { return slots_.size(); }
  SlotType maximal_number_of_slots() const { return max_slots_;};
  virtual SlotIn<DATATYPE> *slot(std::size_t index) {
    return slots_[index].get();
  }
  SlotIn<DATATYPE> *dataslot(std::size_t index) { return slots_[index].get(); }

  std::string datatype() const override { return DATATYPE::datatype(); }

  const StreamInfo<DATATYPE> &streaminfo(std::size_t index) {
    return slots_[index]->streaminfo();
  }

protected:
  void NewSlot(int n = 1);


private:
  typename DATATYPE::Capabilities capabilities_;
  std::vector<std::unique_ptr<SlotIn<DATATYPE>>> slots_;
  SlotType max_slots_;
};

#include "t_streamports.ipp"
