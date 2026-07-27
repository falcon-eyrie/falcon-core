set -e
VERSION="4.1.2"
INSTALLER="cmake-$VERSION-linux-x86_64.sh"

curl -fsSL "https://github.com/Kitware/CMake/releases/download/v$VERSION/$INSTALLER" -o "/tmp/$INSTALLER"
sudo sh "/tmp/$INSTALLER" --prefix=/usr/local --skip-license
rm -f "/tmp/$INSTALLER"

which cmake && cmake --version
