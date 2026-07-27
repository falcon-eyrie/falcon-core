#!/bin/sh
set -e

LLVM_VERSION=22

curl -fsSL https://apt.llvm.org/llvm.sh | sudo bash -s -- "$LLVM_VERSION" all

sudo ln -sf /usr/lib/llvm-22/bin/* /usr/local/bin/

lldb-dap --version