#!/bin/sh
set -eu

print_usage() {
  cat <<EOF
Usage: $0 [--app-dir PATH] [--desktop PATH] [--no-cache-update]

Installs Zed user assets:
  - symlink:   \$HOME/.local/bin/zed -> \$APP_DIR/bin/zed
  - icon:      \$HOME/.local/share/icons/hicolor/512x512/apps/zed.png
  - servicemenu: \$HOME/.local/share/kio/servicemenus/openInZed.desktop

Options:
  --app-dir PATH     Path to the Zed app directory (default: \$HOME/.local/zed.app)
  --desktop PATH     Source .desktop file to install (default: ./openInZed.desktop)
  --no-cache-update  Don't run icon/ KDE cache update commands
  -h, --help         Show this help
EOF
}

APP_DIR="$HOME/.local/zed.app"
SRC_DESKTOP="./openInZed.desktop"
DO_UPDATE_CACHE=1

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
    --no-cache-update)
      DO_UPDATE_CACHE=0; shift;;
    -h|--help)
      print_usage; exit 0;;
    *)
      echo "Unknown arg: $1"; print_usage; exit 2;;
  esac
done

if [ ! -f "$SRC_DESKTOP" ]; then
  echo "Source desktop file not found: $SRC_DESKTOP"
  exit 1
fi

if [ ! -x "$APP_DIR/bin/zed" ]; then
  echo "Warning: zed binary not found or not executable at $APP_DIR/bin/zed"
  echo "If Zed is installed elsewhere, re-run with --app-dir"
fi

# locations
USER_BIN="$HOME/.local/bin"
USER_ICON_DIR="$HOME/.local/share/icons/hicolor/512x512/apps"
USER_ICON_PATH="$USER_ICON_DIR/zed.png"
USER_SERVICEMENU_DIR="$HOME/.local/share/kio/servicemenus"
DEST_DESKTOP_PATH="$USER_SERVICEMENU_DIR/$(basename "$SRC_DESKTOP")"

echo "Installing Zed user assets..."
echo "APP_DIR: $APP_DIR"
echo "SRC_DESKTOP: $SRC_DESKTOP"
echo

mkdir -p "$USER_BIN"
if [ -e "$USER_BIN/zed" ]; then
  if [ "$(readlink -f "$USER_BIN/zed")" = "$(readlink -f "$APP_DIR/bin/zed")" ]; then
    echo "Symlink $USER_BIN/zed already correct."
  else
    echo "Backing up existing $USER_BIN/zed to $USER_BIN/zed.bak"
    mv "$USER_BIN/zed" "$USER_BIN/zed.bak"
    ln -s "$APP_DIR/bin/zed" "$USER_BIN/zed"
    echo "Created symlink $USER_BIN/zed -> $APP_DIR/bin/zed"
  fi
else
  ln -s "$APP_DIR/bin/zed" "$USER_BIN/zed"
  echo "Created symlink $USER_BIN/zed -> $APP_DIR/bin/zed"
fi

mkdir -p "$USER_ICON_DIR"
SRC_ICON_CANDIDATE="$APP_DIR/share/icons/hicolor/512x512/apps/zed.png"
if [ -f "$SRC_ICON_CANDIDATE" ]; then
  cp -f "$SRC_ICON_CANDIDATE" "$USER_ICON_PATH"
  echo "Copied icon from $SRC_ICON_CANDIDATE -> $USER_ICON_PATH"
else
  REPO_ICON="./zed.png"
  if [ -f "$REPO_ICON" ]; then
    cp -f "$REPO_ICON" "$USER_ICON_PATH"
    echo "Copied icon from repo $REPO_ICON -> $USER_ICON_PATH"
  else
    echo "No icon found at $SRC_ICON_CANDIDATE or $REPO_ICON. Skipping icon copy."
  fi
fi

mkdir -p "$USER_SERVICEMENU_DIR"
sed_script='
s/^Icon=.*/Icon=zed/
s/^Exec=.*/Exec=zed %u/
'
sed "$sed_script" "$SRC_DESKTOP" > "$DEST_DESKTOP_PATH"
chmod 644 "$DEST_DESKTOP_PATH"
echo "Installed desktop servicemenu to $DEST_DESKTOP_PATH (Icon=zed, Exec=zed %u)"

echo
echo "Done. Installed:"
echo " - Launcher: $USER_BIN/zed -> $APP_DIR/bin/zed"
echo " - Icon: $USER_ICON_PATH"
echo " - Service menu: $DEST_DESKTOP_PATH"
echo
echo "Next steps (if you don't see the icon immediately):"
echo " - Run: kbuildsycoca5"
echo " - Or log out and back in, or restart plasmashell"
