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

#include "math_numeric.hpp"
#include <cmath>

int next_pow2(int n) {
    n--;
    n |= n >> 1;
    n |= n >> 2;
    n |= n >> 4;
    n |= n >> 8;
    n |= n >> 16;
    n++;
    return n;
}

bool compare_doubles(double A, double B, double maxAbsoluteError,
                     double maxRelativeError) {
    // adapted from
    // http://www.cygnus-software.com/papers/comparingfloats/Comparing%20floating%20point%20numbers.htm#_Toc135149453

    if ((std::fabs(A - B) <= maxAbsoluteError)) {
        return true;
    }

    double relativeError;

    if (std::fabs(B) > std::fabs(A)) {
        relativeError = std::fabs((A - B) / B);
    } else {
        relativeError = std::fabs((A - B) / A);
    }

    if (relativeError <= maxRelativeError) {
        return true;
    }

    return false;
}
