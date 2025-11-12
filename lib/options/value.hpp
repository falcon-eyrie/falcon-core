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

#include <functional>
#include <map>
#include <regex>
#include <stdexcept>
#include <string>
#include <vector>

#include "yaml-cpp/yaml.h"

#include "../utilities/string.hpp"
#include "units/units.hpp"
#include "validation.hpp"

namespace options {

class ValueBase {
  public:
    ValueBase() {}
    virtual ~ValueBase() {}

    virtual void from_yaml(const YAML::Node &node) = 0;
    virtual YAML::Node to_yaml() const = 0;

    virtual bool is_nullable() const = 0;

    virtual bool is_null() const = 0;
    virtual void set_null() = 0;

  protected:
    virtual void unset_null() = 0;
};

template <typename T> T generic_fromyaml(const YAML::Node &node) {
    return node.as<T>();
}

template <typename T> YAML::Node generic_toyaml(const T &x) {
    YAML::Node node;
    node = x;

    return node;
}

template <typename T, bool Nullable = true> class Value : public ValueBase {
  public:
    using ValueType = T;
    using ValidatorType = ValidatorFunc<T>;

    Value(const T &value, ValidatorType validator = {})
        : ValueBase(), validator_(validator) {
        set_value(value);
    }

    Value(ValidatorType validator = {}) : ValueBase(), validator_(validator) {
        if constexpr (!Nullable) {
            set_value(T());
        }
    }

    T validate(T value) {
        if (validator_) {
            return validator_(value);
        }
        return value;
    }

    void from_yaml(const YAML::Node &node) override {
        set_value(generic_fromyaml<T>(node));
    }

    YAML::Node to_yaml() const override {
        YAML::Node node;

        if (is_nullable() && is_null()) {
            return node;
        }

        node = generic_toyaml(value_);

        return node;
    }

    const T &get_value() const {
        if constexpr (Nullable) {
            if (is_null()) {
                throw std::runtime_error("Value has not been set.");
            }
        }
        return value_;
    }

    const T &operator()() const { return get_value(); }

    void set_value(const T &value) {
        value_ = validate(value);
        if constexpr (Nullable) {
            unset_null();
        }
    }

    Value<T, Nullable> &operator=(const T &value) {
        set_value(value);
        return (*this);
    }

    Value<T, Nullable> &operator=(const Value<T> &value) {
        set_value(value());
        return (*this);
    }

    void set_validator(ValidatorType validator = {}) { validator_ = validator; }

    bool is_nullable() const final { return Nullable; }

    bool is_null() const final {
        if constexpr (Nullable) {
            return value_is_null_;
        } else {
            throw std::runtime_error("Value::is_null : value is not nullable.");
        }
    }

    void set_null() final {
        if constexpr (Nullable) {
            value_is_null_ = true;
        } else {
            throw std::runtime_error(
                "Value::set_null : value is not nullable.");
        }
    }

  protected:
    void unset_null() final {
        if constexpr (Nullable) {
            value_is_null_ = false;
        } else {
            throw std::runtime_error(
                "Value::unset_null : value is not nullable.");
        }
    }

  private:
    T value_;
    ValidatorType validator_;
    bool value_is_null_ = true;
};

using Bool = Value<bool, false>;
using NullableBool = Value<bool, true>;

using Double = Value<double, false>;
using NullableDouble = Value<double, true>;

using Int = Value<int, false>;
using NullableInt = Value<int, true>;

using String = Value<std::string, false>;
using NullableString = Value<std::string, true>;

template <typename T> std::vector<T> vector_fromyaml(const YAML::Node &node) {
    if (node.IsSequence()) {
        return node.as<std::vector<T>>();
    } else if (node.IsNull()) {
        return std::vector<T>();
    } else {
        return std::vector<T>({node.as<T>()});
    }
}

template <typename T, bool Nullable = false>
class Vector : public Value<std::vector<T>, Nullable> {
  public:
    Vector(const std::vector<T> &value = {},
           ValidatorFunc<std::vector<T>> validator = {})
        : Value<std::vector<T>, Nullable>(value, validator) {}

    void from_yaml(const YAML::Node &node) override {
        this->set_value(vector_fromyaml<T>(node));
    }
};

template <typename VT> class ValueMap : public ValueBase {
  public:
    using ValueType = typename VT::ValueType;

    ValueMap(const VT &value = VT(),
             const std::map<std::string, ValueType> map = {})
        : ValueBase(), default_(value) {
        set_map(map);
    }

    void set_map(std::map<std::string, ValueType> m) {
        std::map<std::string, VT> tmp;

        for (auto &k : m) {
            tmp.emplace(k.first, default_);
            tmp[k.first] = k.second;
        }

        map_ = tmp;
    }

    virtual void from_yaml(const YAML::Node &node) {
        if (!node.IsMap()) {
            throw std::runtime_error("Not a map");
        }

        set_map(node.as<std::map<std::string, ValueType>>());
    }

    virtual YAML::Node to_yaml() const {
        YAML::Node node = YAML::Node(YAML::NodeType::Map);

        for (auto &k : map_) {
            node[k.first] = k.second.to_yaml();
        }
        return node;
    }

    VT &operator[](const std::string &key) {
        // if key is not in map
        if (!map_.count(key)) {
            map_.emplace(key, default_);
        }
        return map_[key];
    }

    std::map<std::string, ValueType> get_map() const {
        std::map<std::string, ValueType> m;

        for (auto &k : map_) {
            m[k.first] = k.second();
        }

        return m;
    }

    std::map<std::string, ValueType> operator()() const { return get_map(); }

    virtual bool is_nullable() const { return false; }

    virtual bool is_null() const { throw std::runtime_error("Not nullable."); }
    virtual void set_null() { throw std::runtime_error("Not nullable."); }

  protected:
    virtual void unset_null() { throw std::runtime_error("Not nullable."); }

  protected:
    std::map<std::string, VT> map_;
    VT default_;
};

template <typename T> class measurement_toyaml {
  public:
    measurement_toyaml(units::precise_unit u) : units_(u) {}

    YAML::Node operator()(const T &x) {
        YAML::Node node;

        node = std::to_string(x) + " " + units::to_string(units_);

        return node;
    }

  protected:
    units::precise_unit units_;
};

template <typename T> class measurement_fromyaml {
  public:
    measurement_fromyaml(units::precise_unit u) : units_(u) {}

    T operator()(const YAML::Node &node) {
        std::string s = node.as<std::string>();
        auto m = units::measurement_from_string(s);

        if (!units_.has_same_base(m.units())) {
            throw std::runtime_error("Incorrect units. Not same base.");
        }

        double value = m.value_as(units_);

        if (std::isnan(value)) {
            throw std::runtime_error("Incorrect units: NaN");
        }

        return T(value);
    }

  protected:
    units::precise_unit units_;
};

template <typename T, bool Nullable = false>
class Measurement : public Value<T, Nullable> {
  public:
    Measurement(T value, std::string u, ValidatorFunc<T> validator = {},
                std::vector<std::string> alt = {})
        : Value<T, Nullable>(value, validator), index_(0) {
        all_unit_repr_.reserve(1 + alt.size());
        all_unit_repr_.push_back(u);
        all_unit_repr_.insert(all_unit_repr_.end(), alt.begin(), alt.end());

        for (auto &k : all_unit_repr_) {
            if (k.size() == 0) {
                all_unit_.push_back(units::precise::one);
            } else {
                all_unit_.push_back(units::unit_from_string(k));
            }
        }

        repr_unit_ = all_unit_[0];
        repr_unit_str_ = all_unit_repr_[0];
    }

    void set_repr_unit(std::string s) {
        if (s.size() == 0) {
            return;
        }

        // check that it is the same base units
        auto u = units::unit_from_string(s);
        if (!u.equivalent_non_counting(all_unit_[index_])) {
            throw std::runtime_error(
                "Representation unit (" + units::to_string(u) +
                ") are not compatible with base unit (" +
                units::to_string(all_unit_[index_]) + ").");
        }
        repr_unit_ = u;
        repr_unit_str_ = s;
    }

    units::precise_unit unit() const { return all_unit_[index_]; }

    std::string to_string() const {
        double factor = units::convert(repr_unit_, all_unit_[index_]);
        std::ostringstream out;
        out << T(this->get_value() / factor);
        return (out.str() + " " + repr_unit_str_);
    }

    void from_yaml(const YAML::Node &node) override {
        std::string s = node.as<std::string>();

        // split number from unit
        std::regex re("^\\s*([+-]?[0-9,.]*(?:e[+-]?[0-9]*)?)\\s*(.*)?$");
        std::smatch m;
        if (!std::regex_match(s, m, re)) {
            throw std::runtime_error("Could not convert yaml to value.");
        }

        size_t idx = 0;
        bool matched = false;
        double factor = 1.;

        if (m.size() > 2 && m[2].str().size() > 0) {
            auto u = units::unit_from_string(m[2].str());

            for (idx = 0; idx < all_unit_.size(); ++idx) {
                if ((matched = u.equivalent_non_counting(all_unit_[idx]))) {
                    factor = units::convert(u, all_unit_[idx]);
                    break;
                }
            }

            if (!matched) {
                throw std::runtime_error(
                    "Representation unit (" + units::to_string(u) +
                    ") are not compatible with any permissable unit.");
            }
        }

        this->set_value(from_string<T>(m[1].str()) * factor);

        this->index_ = idx;
        this->set_repr_unit(m[2].str());
    }

    YAML::Node to_yaml() const override {
        YAML::Node node;
        node = this->to_string();
        return node;
    }

    Measurement<T, Nullable> &operator=(const T &value) {
        this->set_value(value);
        return (*this);
    }

    Measurement<T, Nullable> &operator=(const Value<T> &value) {
        this->set_value(value());
        return (*this);
    }

  protected:
    size_t index_;
    units::precise_unit repr_unit_;
    std::string repr_unit_str_;
    std::vector<std::string> all_unit_repr_;
    std::vector<units::precise_unit> all_unit_;
};

} // namespace options
