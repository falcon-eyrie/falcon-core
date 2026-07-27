#include <chrono>
#include <string>
#include "iprocessor.hpp"

#include "dummy_data.cpp"
class DummyWriter : public IProcessor {
   private:
    PortOut<DummyType>* event_port_;
    options::Measurement<double> event_rate_{1, "Hz", options::positive<double>()};
    options::String value_{};

   public:
    DummyWriter() : IProcessor() {
        add_option("rate", event_rate_, "Rate (in Hz) at which dummy data is generated.");
    }

    void CreatePorts() override {
        event_port_ = create_output_port<DummyType>("output", DummyType::Parameters(),
                                                    PortOutPolicy(SlotRange(1)));
    }

    void Process(ProcessingContext& context) override {
        DummyType::Data* data = nullptr;

        std::default_random_engine generator;

        auto delay = std::chrono::milliseconds(static_cast<unsigned int>(1000.0 / event_rate_()));

        while (!context.terminated()) {
            std::this_thread::sleep_for(delay);
            data = event_port_->slot(0)->ClaimData(false);
            data->set_value(value_());
            event_port_->slot(0)->PublishData();
        }
    }
};

REGISTERPROCESSOR(DummyWriter)
