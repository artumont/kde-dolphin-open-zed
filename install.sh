#!/bin/sh
set -eu

print_usage() {
  cat <<EOF
Usage: $0 [--app-dir PATH] [--desktop PATH]

Installs Zed user assets:
  - symlink:   \$HOME/.local/bin/zed -> \$APP_DIR/bin/zed
  - icon:      \$HOME/.local/share/icons/hicolor/512x512/apps/zed.png
  - servicemenu: \$HOME/.local/share/kio/servicemenus/openInZed.desktop

Options:
  --app-dir PATH     Path to the Zed app directory (default: \$HOME/.local/zed.app)
  --desktop PATH     Source .desktop file to install (default: ./openInZed.desktop)
  -h, --help         Show this help
EOF
}

APP_DIR="$HOME/.local/zed.app"
SRC_DESKTOP="./openInZed.desktop"

while [ $# -gt 0 ]; do
  case "$1" in
    --app-dir)
      shift
      [ $# -gt 0 ] || { echo "Missing value for --app-dir"; exit 2; }
      APP_DIR="$1"; shift;;
    --desktop)
      shift
      [ $# -gt 0 ] || { echo "Missing value for --desktop"; exit 2; }
      SRC_DESKTOP="$1"; shift;;
    -h|--help)
      print_usage; exit 0;;
    *)
      echo "Unknown arg: $1"; print_usage; exit 2;;
  esac
done

# Validate inputs
if [ ! -f "$SRC_DESKTOP" ]; then
  echo "Error: Source desktop file not found: $SRC_DESKTOP"
  exit 1
fi

if [ ! -x "$APP_DIR/bin/zed" ]; then
  echo "Warning: zed binary not found or not executable at $APP_DIR/bin/zed"
  echo "If Zed is installed elsewhere, re-run with --app-dir"
fi

# Paths
USER_SERVICEMENU_DIR="$HOME/.local/share/kio/servicemenus"
DEST_DESKTOP_PATH="$USER_SERVICEMENU_DIR/$(basename "$SRC_DESKTOP")"

echo "Installing Zed user assets..."
echo "APP_DIR: $APP_DIR"
echo "SRC_DESKTOP: $SRC_DESKTOP"
echo

USER_ICON_PATH="$HOME/.local/share/icons/hicolor/512x512/apps/zed.png"

REPO_ICON="./zed.png"
if [ -f "$REPO_ICON" ]; then
  cp -f "$REPO_ICON" "$USER_ICON_PATH"
  echo "Copied icon from repo $REPO_ICON -> $USER_ICON_PATH"
else
  echo "No icon found at $REPO_ICON. Skipping icon copy."
fi

# Install and rewrite .desktop file
mkdir -p "$USER_SERVICEMENU_DIR"
chmod +x "$DEST_DESKTOP_PATH"
echo "Installed service menu to $DEST_DESKTOP_PATH"

echo
echo "Installation complete!"
echo
echo "If the icon doesn't appear immediately in Dolphin, try:"
echo "  - Log out and back in"
echo "  - Or run: kbuildsycoca5"
