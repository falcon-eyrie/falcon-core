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

#include <cassert>
#include <iterator>

template <class Iter_T> class stride_iter {
  public:
    typedef typename std::iterator_traits<Iter_T>::value_type value_type;
    typedef typename std::iterator_traits<Iter_T>::reference reference;
    typedef
        typename std::iterator_traits<Iter_T>::difference_type difference_type;
    typedef typename std::iterator_traits<Iter_T>::pointer pointer;
    typedef std::random_access_iterator_tag iterator_category;
    typedef stride_iter self;

    // constructors
    stride_iter() : m(NULL), step(0) {}
    stride_iter(const self &x) : m(x.m), step(x.step) {}
    stride_iter(Iter_T x, difference_type n) : m(x), step(n) {}

    // operators
    self &operator++() {
        m += step;
        return *this;
    }
    self operator++(int) {
        self tmp = *this;
        m += step;
        return tmp;
    }
    self &operator+=(const difference_type x) {
        m += (x * step);
        return *this;
    }
    self &operator--() {
        m -= step;
        return *this;
    }
    self operator--(int) {
        self tmp = *this;
        m -= step;
        return tmp;
    }
    self &operator-=(const difference_type x) {
        m -= x * step;
        return *this;
    }
    reference operator[](const difference_type n) { return m[n * step]; }
    reference operator*() { return *m; }

    // friend operators
    friend bool operator==(const self &x, const self &y) {
        assert(x.step == y.step);
        return x.m == y.m;
    }
    friend bool operator!=(const self &x, const self &y) {
        assert(x.step == y.step);
        return x.m != y.m;
    }
    friend bool operator<(const self &x, const self &y) {
        assert(x.step == y.step);
        return x.m < y.m;
    }
    friend difference_type operator-(const self &x, const self &y) {
        assert(x.step == y.step);
        return (x.m - y.m) / x.step;
    }

    friend self operator+(const self &x, difference_type y) {
        return self(x.m + (y * x.step), x.step);
    }
    friend self operator+(difference_type x, const self &y) { return y + x; }

    friend self operator-(const self &x, difference_type y) {
        return self(x.m - (y * x.step), x.step);
    }

  private:
    Iter_T m;
    difference_type step;
};
