#!/bin/bash
set -e

NAMESPACE="org.falcon-eyrie.falcon_gui"
BASE_DIR="$HOME/.local/share/$NAMESPACE"

LATEST_VERSION="2.0.0"
RELEASE_BUNDLE_URL="https://github.com/falcon-eyrie/falcon-core/releases/download/v$LATEST_VERSION/falcon_linux_v$LATEST_VERSION.tar.gz"
DESKTOP_ENTRY="$HOME/.local/share/applications/$NAMESPACE.desktop"

DEPS=("curl" "libgtk-3-0" "libzmq5")

echo "Installing Falcon, please wait..."

sudo apt-get update -qq
for dep in "${DEPS[@]}"; do
    if ! dpkg -s "$dep" >/dev/null 2>&1; then
        sudo apt-get install -y -qq "$dep"
    fi
done

mkdir -p "$BASE_DIR"

curl -L "$RELEASE_BUNDLE_URL" -o "$BASE_DIR/falcon_linux_v$LATEST_VERSION.tar.gz"
tar -xzf "$BASE_DIR/falcon_linux_v$LATEST_VERSION.tar.gz" -C "$BASE_DIR" --strip-components=1
rm "$BASE_DIR/falcon_linux_v$LATEST_VERSION.tar.gz"


cat <<EOF > "$DESKTOP_ENTRY"
[Desktop Entry]
Version=$LATEST_VERSION
Type=Application
Name=Falcon
Exec=$BASE_DIR/falcon_gui
Icon=$BASE_DIR/icon.png
Terminal=false
Categories=Utility;
EOF

chmod +x "$DESKTOP_ENTRY"
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications"
fi

echo "Installation complete."
