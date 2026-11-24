#!/bin/sh
# Install Ebb for the current user:  ./install.sh
# Remove it again:                   ./install.sh --uninstall   (keeps your config)
set -eu

ID=io.github.tomiloba21.Ebb
SRC=$(cd "$(dirname "$0")" && pwd)
BIN_DIR=${XDG_BIN_HOME:-$HOME/.local/bin}
DATA=${XDG_DATA_HOME:-$HOME/.local/share}
CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}/ebb/config.toml

refresh() {
    update-desktop-database "$DATA/applications" 2>/dev/null || true
    gtk-update-icon-cache -f -t "$DATA/icons/hicolor" 2>/dev/null || true
}

if [ "${1:-}" = "--uninstall" ]; then
    rm -f "$BIN_DIR/ebb" "$DATA/applications/$ID.desktop" "$DATA/icons/hicolor/scalable/apps/$ID.svg"
    refresh
    echo "Ebb removed. Your config is still at $CONFIG"
    exit 0
fi

if ! python3 -c 'import tomllib, gi; gi.require_version("Gtk", "4.0"); gi.require_version("Adw", "1")
from gi.repository import Adw; assert (Adw.get_major_version(), Adw.get_minor_version()) >= (1, 6)' 2>/dev/null; then
    echo "Ebb needs Python 3.11+, GTK 4, libadwaita 1.6+ and PyGObject. See the README for install commands." >&2
    exit 1
fi

install -Dm755 "$SRC/ebb" "$BIN_DIR/ebb"
install -Dm644 "$SRC/data/$ID.svg" "$DATA/icons/hicolor/scalable/apps/$ID.svg"
mkdir -p "$DATA/applications"
sed "s|@BIN@|$BIN_DIR/ebb|" "$SRC/data/$ID.desktop.in" > "$DATA/applications/$ID.desktop"

refresh
echo "Ebb installed. Open it from your app menu, or run: ebb"
case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) echo "Note: $BIN_DIR is not on your PATH, so 'ebb' only works as $BIN_DIR/ebb in a terminal." \
            "Add it with: echo 'export PATH=\"$BIN_DIR:\$PATH\"' >> ~/.bashrc" ;;
esac
