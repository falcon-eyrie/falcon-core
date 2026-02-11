#!/bin/bash
set -e

NAMESPACE="org.falcon-eyrie.falcon_gui"
BASE_DIR="$HOME/.local/share/$NAMESPACE"
REPO="falcon-eyrie/falcon-core"

echo "Fetching latest version information..."
LATEST_VERSION=$(wget -qO- "https://api.github.com/repos/$REPO/releases/latest" | grep -Po '"tag_name": "\K[^"]*')

if [ -z "$LATEST_VERSION" ]; then
    echo "Error: Could not fetch latest version. Check your internet connection or repository name."
    exit 1
fi

RELEASE_BUNDLE_URL="https://github.com/$REPO/releases/download/$LATEST_VERSION/falcon_linux_$LATEST_VERSION.tar.gz"
DESKTOP_ENTRY="$HOME/.local/share/applications/$NAMESPACE.desktop"
DEPS=("libgtk-3-0" "libzmq5")

echo "Installing Falcon $LATEST_VERSION, please wait..."

mkdir -p "$BASE_DIR"

wget -qL "$RELEASE_BUNDLE_URL" -O "$BASE_DIR/falcon_bundle.tar.gz"
tar -xzf "$BASE_DIR/falcon_bundle.tar.gz" -C "$BASE_DIR" --strip-components=1
rm "$BASE_DIR/falcon_bundle.tar.gz"

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
[ -x "$(command -v update-desktop-database)" ] && update-desktop-database "$HOME/.local/share/applications"

echo "Falcon needs following dependencies: ${DEPS[*]}"
echo "Checking and installing dependencies..."
sudo apt-get update -qq >/dev/null 2>&1
for dep in "${DEPS[@]}"; do
    if ! dpkg -s "$dep" >/dev/null 2>&1; then
        echo "✓  Installing: $dep"
        sudo apt-get install -y -qq "$dep" >/dev/null 2>&1
    else
        echo "✓  Skipping $dep, already installed."
    fi
done

echo "✓ Falcon $LATEST_VERSION installed to $BASE_DIR"
echo "You can launch Falcon from the application menu."