#!/data/data/com.termux/files/usr/bin/bash
# ================================================
# Sfixx x OSINT - Termux Installer
# ================================================

set -e

C_RESET='\033[0m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_RED='\033[1;31m'
C_CYAN='\033[1;36m'

info() { echo -e "${C_CYAN}[*]${C_RESET} $*"; }
ok()   { echo -e "${C_GREEN}[+]${C_RESET} $*"; }
warn() { echo -e "${C_YELLOW}[!]${C_RESET} $*"; }
err()  { echo -e "${C_RED}[x]${C_RESET} $*"; }

# --- Check Termux ---
if [ ! -d "/data/data/com.termux" ]; then
    err "Installer ini khusus untuk Termux di Android."
    err "Untuk sistem lain, install manual sesuai README."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="${PREFIX:-/data/data/com.termux/files/usr}/bin"

# --- Update repo ---
info "Update package repository..."
pkg update -y || warn "pkg update gagal, lanjut saja."

# --- Install dependencies ---
info "Menginstall dependencies..."
# Yang WAJIB:
pkg install -y git curl python

# Yang OPSIONAL (dipakai modul tertentu):
pkg install -y dnsutils whois || warn "dnsutils/whois gagal diinstall (opsional)."

# --- Verify wajib ---
for dep in git curl python; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        err "Gagal menginstall dependency wajib: $dep"
        exit 1
    fi
done

# --- Set permission ---
info "Mengatur permission file..."
chmod +x "$SCRIPT_DIR/sfixx"           2>/dev/null || true
chmod +x "$SCRIPT_DIR/install.sh"      2>/dev/null || true
chmod +x "$SCRIPT_DIR/uninstall.sh"    2>/dev/null || true
chmod +x "$SCRIPT_DIR/update.sh"       2>/dev/null || true
chmod +x "$SCRIPT_DIR/modules/"*.sh    2>/dev/null || true
chmod +x "$SCRIPT_DIR/assets/"*.sh     2>/dev/null || true

# --- Buat command 'sfixx' ---
info "Membuat command 'sfixx' di $BIN_DIR..."
cat > "$BIN_DIR/sfixx" << EOF
#!/data/data/com.termux/files/usr/bin/bash
exec "$SCRIPT_DIR/sfixx" "\$@"
EOF
chmod +x "$BIN_DIR/sfixx"

ok "Instalasi selesai!"
echo
echo -e "${C_GREEN}Jalankan:${C_RESET}  sfixx"
echo -e "${C_GREEN}Atau    :${C_RESET}  sfixx help"
echo -e "${C_GREEN}Update  :${C_RESET}  sfixx update"
echo -e "${C_GREEN}Uninstall:${C_RESET} bash uninstall.sh"
echo