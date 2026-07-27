#include <chrono>
#include "dummy_data.cpp"
#include "iprocessor.hpp"

class DummyReader : public IProcessor {
   protected:
    PortIn<DummyType>* event_port_;

   public:
    void CreatePorts() override {
        event_port_ = create_input_port<DummyType>("input", DummyType::Capabilities(),
                                                   PortInPolicy(SlotRange(1)));
    }

    void Process(ProcessingContext& context) override {
        DummyType::Data* data;

        while (!context.terminated()) {
            if (!event_port_->slot(0)->RetrieveData(data)) {
                break;
            }

            LOG(UPDATE) << name() << ": received event " << data->value() << ".";

            event_port_->slot(0)->ReleaseData();
        }
    }
};

REGISTERPROCESSOR(DummyReader)
