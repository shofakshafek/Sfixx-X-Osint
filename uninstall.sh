#!/data/data/com.termux/files/usr/bin/bash
# Sfixx x OSINT - Uninstaller

C_RESET='\033[0m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'

info() { echo -e "${C_GREEN}[*]${C_RESET} $*"; }
warn() { echo -e "${C_YELLOW}[!]${C_RESET} $*"; }

BIN_DIR="${PREFIX:-/data/data/com.termux/files/usr}/bin"
CMD_PATH="$BIN_DIR/sfixx"

if [ -f "$CMD_PATH" ]; then
    rm -f "$CMD_PATH"
    info "Command 'sfixx' dihapus dari $CMD_PATH"
else
    warn "Command 'sfixx' tidak ditemukan."
fi

info "Uninstall selesai."
warn "Untuk menghapus seluruh project: rm -rf \"$(cd "$(dirname "$0")" && pwd)\""