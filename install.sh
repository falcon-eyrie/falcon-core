#!/bin/bash
set -e

NAMESPACE="org.falcon-eyrie.falcon_gui"
BASE_DIR="$HOME/.local/share/$NAMESPACE"

LATEST_VERSION="2.0.0-rc1"
RELEASE_BUNDLE_URL="https://github.com/falcon-eyrie/falcon-core/releases/download/v$LATEST_VERSION/falcon_linux_v$LATEST_VERSION.tar.gz"
DESKTOP_ENTRY="$HOME/.local/share/applications/$NAMESPACE.desktop"

DEPS=("libgtk-3-0" "libzmq5")

echo "Installing Falcon, please wait..."


mkdir -p "$BASE_DIR"

wget -qL "$RELEASE_BUNDLE_URL" -O "$BASE_DIR/falcon_linux_v$LATEST_VERSION.tar.gz"
tar -xzf "$BASE_DIR/falcon_linux_v$LATEST_VERSION.tar.gz" -C "$BASE_DIR" --strip-components=1
rm "$BASE_DIR/falcon_linux_v$LATEST_VERSION.tar.gz"

echo "Falcon v$LATEST_VERSION installed to $BASE_DIR"

echo "Creating desktop entry at $DESKTOP_ENTRY..."

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

echo "Downloading following dependencies: ${DEPS[*]}"

echo "This may require sudo password..."

sudo apt-get update -qq
for dep in "${DEPS[@]}"; do
    if ! dpkg -s "$dep" >/dev/null 2>&1; then
        echo "Installing $dep..."
        sudo apt-get install -y -qq "$dep"
    fi
done

echo "Installation complete! You can launch Falcon from the application menu."
