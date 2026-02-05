
#include <utility>

#include "idata.hpp"

namespace nsDummyType {

using ParentType = AnyType;

struct Parameters {
    Parameters(std::string value = "") : value(std::move(value)) {}

    std::string value;
};

class Data : public IData<Data, ParentType> {
   public:
    using BaseClass = IData<Data, ParentType>;

    Data(std::string value = "") : value_(std::move(value)) {}

    Data(const Parameters& parameters) : Data(parameters.value) {}

    static const std::string static_datatype() { return "dummy"; }
    static const std::string static_dataname() { return "dummy"; }

    Parameters parameters() const { return Parameters(value_); }

    void ClearData() override { value_.clear(); }
    std::string value() const { return value_; }
    void set_value(std::string value) { value_ = std::move(value); }
    void set_value(const Data& other) { value_ = other.value(); }

    friend bool operator==(const Data& e1, const Data& e2) { return e1.value_ == e2.value_; }
    friend bool operator!=(const Data& e1, const Data& e2) { return e1.value_ != e2.value_; }

    void SerializeBinary(std::ostream& stream, Serialization::Format format =
                                                   Serialization::Format::FULL) const override {
        /* no-op */
    }
    void SerializeYAML(YAML::Node& node,
                       Serialization::Format format = Serialization::Format::FULL) const override {
        /* no-op */
    }

    void SerializeFlatBuffer(flexbuffers::Builder& fbb) override { /* no-op */ }

    void YAMLDescription(YAML::Node& node, Serialization::Format format =
                                               Serialization::Format::FULL) const override {
        /* no-op */
    }

   protected:
    std::string value_;
};

using Capabilities = ParentType::Capabilities;

}  // namespace nsDummyType

using DummyType = DefineType<nsDummyType::Data, AnyType, true, nsDummyType::Capabilities,
                             nsDummyType::Parameters>;