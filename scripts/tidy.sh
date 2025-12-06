run-clang-tidy -p build -j $(nproc 2>/dev/null || sysctl -n hw.logicalcpu)$(find . \
  -name '*.c'    -o -name '*.cc'   -o -name '*.cpp'  -o -name '*.cxx' -o -name '*.c++' \
  -o -name '*.h' -o -name '*.hh'   -o -name '*.hpp'  -o -name '*.hxx' -o -name '*.h++' \
  | grep -v "./build/" -v "./extensions/")
