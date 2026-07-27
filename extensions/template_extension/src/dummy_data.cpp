#pragma once
#include <string>
#include "idata.hpp"

namespace nsDummyType {
using ParentType = AnyType;
using Capabilities = ParentType::Capabilities;
using Parameters = ParentType::Parameters;

class Data : public IData<Data, ParentType> {
   private:
    std::string value_;
    size_t hash_;

   public:
    using BaseClass = IData<Data, ParentType>;
    Data() : Data("hello") {}
    Data(const std::string& value) { set_value(value); }
    Data(const Parameters _) : Data("hello") {}

    size_t hash() const { return hash_; }
    size_t size() const { return value_.size(); }
    std::string value() const { return value_; }
    void set_value(const std::string& val) {
        value_ = val;
        hash_ = std::hash<std::string>()(value_);
    }
};

}  // namespace nsDummyType

using DummyType = DefineType<nsDummyType::Data, AnyType, true, nsDummyType::Capabilities,
                             nsDummyType::Parameters>;

namespace YAML {
template <>
struct convert<DummyType::Data> {
    static Node encode(const DummyType::Data& rhs) {
        Node node;
        node = rhs.value();
        return node;
    }

    static bool decode(const Node& node, DummyType::Data& rhs) {
        rhs.set_value(node.as<std::string>());
        return true;
    }
};
}  // namespace YAML