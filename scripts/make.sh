#!/bin/sh
set -e
cd build
make -j$(nproc 2>/dev/null)
mkdir -p debug
cp falcon/falcon debug/
cp falcon/tools0/nlxtestbench/nlxtestbench debug/ || true
