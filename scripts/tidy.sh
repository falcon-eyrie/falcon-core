EXTS="
*.c
*.cc
*.cpp
*.cxx
*.c++
*.h
*.hh
*.hpp
*.hxx
*.h++
"

NAME_EXPR=$(printf "%s\n" $EXTS | awk '{printf "-name %s -o ", $0}')

run-clang-tidy \
  -p build \
  -j "$(nproc 2>/dev/null || sysctl -n hw.logicalcpu)" \
  $(
    find . \
      -type f \
      \( $NAME_EXPR -false \) \
      -not -path "./build/*" \
      -not -path "./extensions/*"
  )
