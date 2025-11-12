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

#include <algorithm>
#include <limits>
#include <regex>
#include <stdexcept>
#include <string>
#include <vector>

#include "units/units.hpp"

#include "../utilities/filesystem.hpp"

namespace options {

class ValidationError : public std::runtime_error {
  public:
    ValidationError(std::string msg) : std::runtime_error(msg) {}
};

class ConversionError : public std::runtime_error {
  public:
    ConversionError(std::string msg) : std::runtime_error(msg) {}
};

template <typename T> using ValidatorFunc = std::function<T(const T &)>;

template <typename T>
ValidatorFunc<T> compose(ValidatorFunc<T> f, ValidatorFunc<T> g) {
    return [f, g](T x) { return f(g(x)); };
}

template <typename T> class validator {
  public:
    friend auto operator+(const ValidatorFunc<T> &lhs,
                          const ValidatorFunc<T> &rhs) {
        return compose<T>(rhs, lhs);
    }
};

template <typename T> class inrange : public validator<T> {
    static_assert(std::is_arithmetic<T>::value,
                  "inrange validator only supports numerical types.");

  public:
    using value_type = T;

  public:
    inrange(T min, T max) : min_(min), max_(max) {}

    T operator()(const T &x) const {
        if (x < min_ || x > max_) {
            throw ValidationError("Value out of range.");
        }
        return x;
    }

  protected:
    T min_;
    T max_;
};

template <typename T> class clamped : public validator<T> {
    static_assert(std::is_arithmetic<T>::value,
                  "clamped validator only supports numerical types.");

  public:
    using value_type = T;

  public:
    clamped(T min, T max) : min_(min), max_(max) {}

    T operator()(const T &x) const {
        T y = x;
        std::clamp(y, min_, max_);
        return y;
    }

  protected:
    T min_;
    T max_;
};

template <typename T> class squared : public validator<T> {
    static_assert(std::is_arithmetic<T>::value,
                  "squared validator only supports numerical types.");

  public:
    T operator()(const T &x) const { return x * x; }
};

template <typename T> class multiplied : public validator<T> {
    static_assert(std::is_arithmetic<T>::value,
                  "multiplier validator only supports numerical types.");

  public:
    multiplied(T multiplier) : multiplier_(multiplier) {}

    T operator()(const T &x) const { return multiplier_ * x; }

  protected:
    T multiplier_;
};

class invert : public validator<bool> {
  public:
    bool operator()(const bool &x) const { return !x; }
};

template <typename T> class zeroismax : public validator<T> {
  public:
    T operator()(const T &x) {
        if (x == 0) {
            return std::numeric_limits<T>::max();
        } else {
            return x;
        }
    }
};

template <typename T> class notempty : public validator<T> {
  public:
    T operator()(const T &x) {
        if (x.size() == 0) {
            throw ValidationError("Container or value cannot be empty.");
        }
        return x;
    }
};

template <typename T> class each : public validator<std::vector<T>> {
  public:
    each(ValidatorFunc<T> validator) : validator_(validator) {}

    std::vector<T> operator()(const std::vector<T> &x) {
        std::vector<T> y = x;
        std::transform(x.begin(), x.end(), y.begin(), validator_);
        return x;
    }

  protected:
    ValidatorFunc<T> validator_;
};

template <typename T> class positive : public validator<T> {
  public:
    positive(bool strict = false) : strict_(strict) {}

    T operator()(const T &x) const {
        if ((strict_ && x <= 0) || x < 0) {
            if (strict_) {
                throw ValidationError("Value cannot be negative or zero.");
            } else {
                throw ValidationError("Value cannot be negative.");
            }
        }
        return x;
    }

  protected:
    bool strict_;
};

class isfile : public validator<std::string> {
  public:
    isfile(bool exists = false) : exists_(exists) {}

    std::string operator()(const std::string &x) const {
        return parse_file(x, exists_).string();
    }

  protected:
    bool exists_;
};

class isdir : public validator<std::string> {
  public:
    isdir(bool exists = true, bool create = false)
        : exists_(exists), create_(create) {}

    std::string operator()(const std::string &x) const {
        return parse_directory(x, exists_, create_).string();
    }

  protected:
    bool exists_;
    bool create_;
};

} // namespace options
