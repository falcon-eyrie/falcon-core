#include <chrono>
#include <string>
#include "dummy_data.cpp"
#include "iprocessor.hpp"

class DummyWriter : public IProcessor {
   private:
    PortOut<DummyType>* event_port_;
    options::Measurement<double> freq_{1, "Hz", options::positive<double>()};
    options::String value_{};

   public:
    DummyWriter() : IProcessor() {
        add_option("freq", freq_, "Freq (in Hz) at which dummy data is generated.");
        add_option("message", value_, "Value to write to the output port.");
    }

    void CreatePorts() override {
        event_port_ = create_output_port<DummyType>("output", DummyType::Parameters(),
                                                    PortOutPolicy(SlotRange(1)));
    }

    void Process(ProcessingContext& context) override {
        DummyType::Data* data = nullptr;
        auto delay = std::chrono::milliseconds(static_cast<unsigned int>(1000.0 / freq_()));

        while (!context.terminated()) {
            std::this_thread::sleep_for(delay);
            data = event_port_->slot(0)->ClaimData(false);
            data->set_value(value_());
            event_port_->slot(0)->PublishData();
        }
    }
};

REGISTERPROCESSOR(DummyWriter)
