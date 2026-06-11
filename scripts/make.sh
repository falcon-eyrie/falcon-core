#!/bin/sh
set -e
cd build
make -j$(nproc 2>/dev/null)
mkdir -p debug
cp --remove-destination falcon/falcon debug/
cp --remove-destination falcon/tools0/nlxtestbench/nlxtestbench debug/ || true
