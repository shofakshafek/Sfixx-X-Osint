#!/usr/bin/env bash
# URL analyzer: parsing, response, redirect, suspicious patterns

url_main() {
    local url="$1"
    if [ -z "$url" ]; then
        log_err "URL wajib diisi."
        return 1
    fi

    # Auto-prefix
    if [[ ! "$url" =~ ^https?:// ]]; then
        url="https://$url"
    fi

    if ! check_internet; then
        log_err "Tidak ada koneksi internet."
        return 1
    fi

    log_info "Menganalisa URL: ${C_YELLOW}$url${C_RESET}"
    echo

    # Parse URL
    echo -e "${C_CYAN}── URL Components ──${C_RESET}"
    if require_cmd python3; then
        SFIXX_URL="$url" python3 - << 'PYEOF'
import os
from urllib.parse import urlparse, parse_qs

u = os.environ.get("SFIXX_URL", "")
p = urlparse(u)
print(f"  Scheme    : {p.scheme}")
print(f"  Host      : {p.hostname}")
print(f"  Port      : {p.port or 'default'}")
print(f"  Path      : {p.path or '/'}")
print(f"  Query     : {p.query or '-'}")
print(f"  Fragment  : {p.fragment or '-'}")
if p.query:
    qs = parse_qs(p.query)
    print("  Parameters:")
    for k, v in qs.items():
        print(f"    - {k} = {v}")
PYEOF
    else
        echo "  (python3 tidak tersedia untuk parsing)"
    fi
    echo

    # Response check
    echo -e "${C_CYAN}── Response ──${C_RESET}"
    local result
    result=$(curl -s -o /dev/null \
        -w "Status  : %{http_code}\nTime    : %{time_total}s\nSize    : %{size_download} bytes\nRedirect: %{redirect_url}\nFinal   : %{url_effective}" \
        -L --max-time "${TIMEOUT:-10}" \
        -A "Mozilla/5.0 (Termux; Sfixx-OSINT)" "$url" 2>/dev/null)
    if [ -z "$result" ]; then
        log_err "Tidak bisa menjangkau URL."
        return 1
    fi
    echo "$result" | sed 's/^/  /'
    echo

    # Shortener / suspicious indicators
    echo -e "${C_CYAN}── Quick Analysis ──${C_RESET}"
    case "$url" in
        *bit.ly*|*t.co*|*tinyurl*|*goo.gl*|*is.gd*|*ow.ly*|*buff.ly*|*cutt.ly*)
            echo -e "  ${C_YELLOW}[!]${C_RESET} URL shortener terdeteksi."
            ;;
    esac
    if [[ "$url" == http://* ]]; then
        echo -e "  ${C_YELLOW}[!]${C_RESET} Menggunakan HTTP (tidak terenkripsi)."
    fi
    if echo "$url" | grep -Eq '(@|%00|\.php\?.*=http)'; then
        echo -e "  ${C_RED}[!]${C_RESET} Pola mencurigakan ditemukan (@, %00, atau redirect param)."
    fi

    log_done "Selesai."
}