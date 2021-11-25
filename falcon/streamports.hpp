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

#include <set>
#include <vector>
#include <memory>
#include <string>

#include "istreamports.hpp"
#include "utilities/math_numeric.hpp"

struct RingBufferStatus {
  uint64_t read;
  uint64_t backlog;
  bool alive;
};

// forward declarations
template <typename DATATYPE> class SlotIn;
template <typename DATATYPE> class PortOut;
template <typename DATATYPE> class PortIn;
int IdentifyNextSlot(int slot_request, int connected_slot_number,
                     bool allow_multi_connect, const PortPolicy &policy);

template <typename DATATYPE> class SlotOut : public ISlotOut {
  friend class PortOut<DATATYPE>;

 public:
  SlotOut(PortOut<DATATYPE> *parent, const SlotAddress &address,
          const typename DATATYPE::Parameters &parameters)
      : ISlotOut(parent, address), streaminfo_(parameters),
        ringbuffer_serial_number_(0) {}

  // public interface
  typename DATATYPE::Data *ClaimData(bool clear);
  std::vector<typename DATATYPE::Data *> ClaimDataN(uint64_t n, bool clear);
  void PublishData();

  virtual StreamInfo<DATATYPE> &streaminfo() { return streaminfo_; }
  const typename DATATYPE::Data &prototype() const {
    return streaminfo_.template getDataPrototype<typename DATATYPE::Data>();
  }
  uint64_t nitems_produced() const;

 protected:
  // called by SlotIn<DATATYPE>
  virtual typename DATATYPE::Data *DataAt(int64_t sequence) const {
    return ringbuffer_->Get(sequence);
  }

  void CreateRingBuffer(int buffer_size, WaitStrategy wait_strategy);
  void Unlock();

  RingBatch *next_batch(uint64_t n = 1);

  virtual void PrepareProcessing() {
    ringbuffer_serial_number_ = 0;

    if (!connected()) {
      return;
    }

    ringbuffer_->ForcePublish(-1L);
    ringbuffer_->Claim(-1L);
  }

 public:
  StreamInfo<DATATYPE>
      streaminfo_;   // owned by SlotOut, once finalized, the streaminfo (and
                     // datatype) are fixed for the life time of the slot(?)
  //std::unique_ptr<DataFactory<DATATYPE>> datafactory_ = nullptr;
  std::unique_ptr<RingBuffer<typename DATATYPE::Data>> ringbuffer_ = nullptr;

 protected:
  uint64_t ringbuffer_serial_number_;
};

template <typename DATATYPE> class PortOut : public IPortOut {
 public:
  PortOut(IProcessor *parent, const PortAddress &address,
//          const typename DATATYPE::Capabilities &capabilities,
          const typename DATATYPE::Parameters &parameters,
          const PortOutPolicy &policy)
      : IPortOut(parent, address, policy), //capabilities_(capabilities),
        parameters_(parameters) {
    NewSlot(policy.min_slot_number());
  }

  SlotType number_of_slots() const override { return slots_.size(); }
  std::string datatype() const override { return DATATYPE::datatype(); }

  StreamInfo<DATATYPE> &streaminfo(std::size_t index) {
    return slots_[index]->streaminfo();
  }

  const typename DATATYPE::Data &prototype(std::size_t index) const {
    return slots_[index]->prototype();
  }

  virtual SlotOut<DATATYPE> *slot(std::size_t index) {
    return slots_[index].get();
  }

  SlotOut<DATATYPE> *dataslot(std::size_t index) { return slots_[index].get(); }

//  virtual const typename DATATYPE::Capabilities &capabilities() const {
//    return capabilities_;
//  }

 protected:
  // called by StreamOutConnector
  void Connect(int slot, ISlotIn *downstream) override;
  int ReserveSlot(int slot) override;

  // called by IPortOut
  void CreateRingBuffers() override;
  void UnlockSlots() override;

  // called by PortOut<DATATYPE>::Connect
  virtual void NewSlot(int n = 1);

  void PrepareProcessing() override {
    for (auto &it : slots_) {
      it->PrepareProcessing();
    }
  }

 private:
//  typename DATATYPE::Capabilities capabilities_;
  typename DATATYPE::Parameters parameters_;  // default parameters
  std::vector<std::unique_ptr<SlotOut<DATATYPE>>> slots_;
};

template <typename DATATYPE> class SlotIn : public ISlotIn {
  friend class PortIn<DATATYPE>;

 public:
  SlotIn(PortIn<DATATYPE> *parent, const SlotAddress &address,
         typename DATATYPE::Capabilities capabilities,
         bool cache = false)
      : ISlotIn(parent, address, cache), capabilities_(capabilities) {
  }


  /**
   * @brief get a prototype example of a data packet - method used from the processor implementation
   * @return  an empty data packet
   */
  //const typename DATATYPE::Data *GetDataPrototype() const;

  /**
   * @brief Retrieve the older data packet in the ring buffer - method used from the processor implementation
   * @param data Container to load the data packet from the ring buffer
   * @param time_out time to wait for a packet in microseconds. If -1, wait for a packet to arrive
   * @return boolean if the slot is connected
   */
  bool RetrieveData(typename DATATYPE::Data *&data, int64_t time_out=-1);
  /**
   * @brief Retrieve N data packets in the ring buffer - method used from the processor implementation
   * @param data Container to load N data packets from the ring buffer
   * @param time_out time to wait for a packet in microseconds. If -1, wait for a packet to arrive
   * @return boolean if the slot is connected
   */
  bool RetrieveDataN(uint64_t n, std::vector<typename DATATYPE::Data *> &data, int64_t time_out=-1);
  /**
   * @brief Retrieve all data packets in the ring buffer - method used from the processor implementation
   * @param data Container to load all data packets from the ring buffer
   * @param time_out time to wait for a packet in microseconds. If -1, wait for a packet to arrive
   * @return boolean if the slot is connected
   */
  bool RetrieveDataAll(std::vector<typename DATATYPE::Data *> &data, int64_t time_out=-1);

  /**
   * @brief Flush all data already in the ring buffer without retrieve them - method used from the processor implementation
   * @return boolean if the slot is connected
   */
  bool FlushData(){
      std::vector<typename DATATYPE::Data *> data;
      if(!RetrieveDataAll(data, 0)){
          return false;
      }

      auto nread = status_read();

      if (nread == 0) {
          ReleaseData();

      }
      return true;

  }
  const IStreamInfo &streaminfo() {
    if (!connected()) {
      throw std::runtime_error("Input slot is not connected");
    }

    NegotiateUpstream();

    return upstream_->streaminfo();
  }

  const typename DATATYPE::Data & prototype() {
    return streaminfo().template getDataPrototype<typename DATATYPE::Data>();
  }

  bool status_alive() const { return status_.alive; }
  uint64_t status_read() const { return status_.read; }
  uint64_t status_backlog() const { return status_.backlog; }

  void Validate() override {
    
    try {
      //auto p = dynamic_cast<typename DATATYPE::Data&>(*prototype);
      
      // the template keyword is necessary here for the compiler
      // to know how to interpret the code
      // see https://stackoverflow.com/a/613132
      auto prototype = this->streaminfo().template getDataPrototype<typename DATATYPE::Data>();
      capabilities_.Validate(prototype);
    } catch (const std::bad_cast &e) {
      throw std::runtime_error("Upstream and downstream data types are incompatible (" + this->streaminfo().datatype() + " -> " + DATATYPE::datatype() + ").");
    } catch (const std::exception &e) {
      throw;
    }
    
  }

 protected:
  void Unlock();
  void check_high_water_level();

  RingBufferStatus status_;

  const double HIGH_WATER_LEVEL = 0.85;
  unsigned int n_messages_;
  const unsigned int MAX_N_MESSAGES = 20;

  typename DATATYPE::Capabilities capabilities_;

 public:
  typename DATATYPE::Data *cache_;
};

template <typename DATATYPE> class PortIn : public IPortIn {
 public:
  PortIn(IProcessor *parent, const PortAddress &address,
         const typename DATATYPE::Capabilities &capabilities,
         const PortInPolicy &policy)
      : IPortIn(parent, address, policy), capabilities_(capabilities) {
    NewSlot(policy.min_slot_number());
  }

  SlotType number_of_slots() const override { return slots_.size(); }

  virtual SlotIn<DATATYPE> *slot(std::size_t index) {
    return slots_[index].get();
  }
  SlotIn<DATATYPE> *dataslot(std::size_t index) { return slots_[index].get(); }

  std::string datatype() const override { return DATATYPE::datatype(); }

  const IStreamInfo &streaminfo(std::size_t index) {
    return slots_[index]->streaminfo();
  }

  const typename DATATYPE::Data & prototype(std::size_t index) {
    return slots_[index]->prototype();
  }

  void PrepareProcessing() override {
    for (auto &it : slots_) {
      it->PrepareProcessing();
    }
  }

 protected:
  // called by StreamInConnector
  virtual void Connect(int slot, ISlotOut *upstream);
  virtual int ReserveSlot(int slot);
//  virtual void VerifyCompatibility(IPortOut *upstream);

  void UnlockSlots() override;
  void NewSlot(int n = 1);

 private:
  // DATATYPE datatype_;
  typename DATATYPE::Capabilities capabilities_;
  std::vector<std::unique_ptr<SlotIn<DATATYPE>>> slots_;
};

#include "streamports.ipp"
