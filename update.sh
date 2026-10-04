#!/data/data/com.termux/files/usr/bin/bash
# Sfixx x OSINT - Update from GitHub

set -e

C_RESET='\033[0m'
C_GREEN='\033[1;32m'
C_RED='\033[1;31m'

info() { echo -e "${C_GREEN}[*]${C_RESET} $*"; }
err()  { echo -e "${C_RED}[x]${C_RESET} $*"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config/config.conf"

if [ ! -d "$SCRIPT_DIR/.git" ]; then
    err "Bukan git repository. Reinstall via git clone."
    exit 1
fi

cd "$SCRIPT_DIR"

# Backup config lokal (kalau user mengubah REPO_URL, dll.)
TMP_BAK=""
if [ -f "$CONFIG_FILE" ]; then
    TMP_BAK="$(mktemp)"
    cp "$CONFIG_FILE" "$TMP_BAK"
fi

info "Mengambil update dari GitHub..."
git fetch --all
git reset --hard origin/main 2>/dev/null || git reset --hard origin/master

# Restore config
if [ -n "$TMP_BAK" ] && [ -f "$TMP_BAK" ]; then
    cp "$TMP_BAK" "$CONFIG_FILE"
    rm -f "$TMP_BAK"
fi

# Pastikan executable
chmod +x "$SCRIPT_DIR/sfixx" 2>/dev/null || true
chmod +x "$SCRIPT_DIR/"*.sh   2>/dev/null || true
chmod +x "$SCRIPT_DIR/modules/"*.sh 2>/dev/null || true

info "Update selesai."