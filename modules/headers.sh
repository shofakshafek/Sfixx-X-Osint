#!/usr/bin/env bash
# HTTP headers inspection

headers_main() {
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

    log_info "Mengambil HTTP headers: ${C_YELLOW}$url${C_RESET}"
    echo

    local out
    out=$(curl -s -I -L --max-time "${TIMEOUT:-10}" \
        -A "Mozilla/5.0 (Termux; Sfixx-OSINT)" "$url" 2>/dev/null)

    if [ -z "$out" ]; then
        log_err "Tidak ada respons dari server. Cek URL / koneksi."
        return 1
    fi

    echo "$out"

    # Security headers summary
    echo
    echo -e "${C_CYAN}── Security Headers Check ──${C_RESET}"
    for h in "Strict-Transport-Security" "Content-Security-Policy" \
             "X-Frame-Options" "X-Content-Type-Options" \
             "Referrer-Policy" "Permissions-Policy"; do
        if echo "$out" | grep -qi "^$h:"; then
            echo -e "  ${C_GREEN}[✓]${C_RESET} $h"
        else
            echo -e "  ${C_RED}[x]${C_RESET} $h"
        fi
    done
}