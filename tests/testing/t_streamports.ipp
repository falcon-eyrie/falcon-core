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
inline uint64_t SlotOut<DATATYPE>::nitems_produced() const {

  return ringbuffer_serial_number_;
}


template <typename DATATYPE>
inline typename DATATYPE::Data *SlotOut<DATATYPE>::ClaimData(bool clear) {

  auto data = new typename DATATYPE::Data();
  data->set_serial_number(ringbuffer_serial_number_++);
  data->Initialize(streaminfo().parameters());
  fake_data.push_back(data);
  return fake_data.back();
}

template <typename DATATYPE> void PortOut<DATATYPE>::NewSlot(int n) {

  SlotAddress address(this->address_, 0);
  for (int k = 0; k < n; k++) {
    address.set_slot(this->slots_.size());
    this->slots_.push_back(std::unique_ptr<SlotOut<DATATYPE>>(
        new SlotOut<DATATYPE>(this, address, parameters_)));
  }
}

template <typename DATATYPE>
const typename DATATYPE::Data *SlotIn<DATATYPE>::GetDataPrototype() const {
  return fake_data[0];
}

template <typename DATATYPE>
bool SlotIn<DATATYPE>::RetrieveData(typename DATATYPE::Data *&data) {
  data = nullptr;
  if (fake_data.size() > 0){
      if (fake_delay.size() > 0 ){
        if(fake_delay[0] > 0) {
          LOG(DEBUG) << "Fake delay of " << fake_delay[0] << "ms";
          std::this_thread::sleep_for(std::chrono::milliseconds(fake_delay[0]));
        }
        fake_delay.pop_front();
      }
      fake_data[0]->set_source_timestamp();
      data = fake_data[0];
      fake_data.pop_front();
      return true;
    }
  return false;
}

template <typename DATATYPE>
bool SlotIn<DATATYPE>::RetrieveDataAll(
    std::vector<typename DATATYPE::Data *> &data) {
  auto data_1 = new typename DATATYPE::Data();
  if(RetrieveData(data_1)){
    data.push_back(data_1);
    return true;
  }
  return false;
}

template <typename DATATYPE> void PortIn<DATATYPE>::NewSlot(int n) {

  SlotAddress address(this->address_, 0);
  for (int k = 0; k < n; k++) {
    address.set_slot(slots_.size());
    slots_.push_back(std::move(std::unique_ptr<SlotIn<DATATYPE>>(
        new SlotIn<DATATYPE>(this, address, capabilities_, policy().time_out(),
                             policy().cache_enabled()))));
  }
}