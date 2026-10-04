#!/usr/bin/env bash
# Domain WHOIS / RDAP information

domain_main() {
    local domain="$1"
    if [ -z "$domain" ]; then
        log_err "Domain wajib diisi."
        return 1
    fi

    # Bersihkan protokol & path
    domain="${domain#http://}"
    domain="${domain#https://}"
    domain="${domain%%/*}"
    domain="${domain%%\?*}"

    if [ -z "$domain" ]; then
        log_err "Domain tidak valid."
        return 1
    fi

    if ! check_internet; then
        log_err "Tidak ada koneksi internet."
        return 1
    fi

    log_info "Mengambil informasi WHOIS untuk: ${C_YELLOW}$domain${C_RESET}"
    echo

    if command -v whois >/dev/null 2>&1; then
        whois "$domain" 2>&1 | head -n 100
        return 0
    fi

    log_warn "whois tidak terpasang, fallback ke RDAP (curl + python)."
    local resp
    resp=$(curl -s --max-time "${TIMEOUT:-10}" "https://rdap.org/domain/$domain")
    if [ -z "$resp" ]; then
        log_err "Gagal mengambil data RDAP. Domain mungkin tidak ditemukan."
        return 1
    fi
    if command -v python3 >/dev/null 2>&1; then
        echo "$resp" | python3 -m json.tool 2>/dev/null | head -n 100 || echo "$resp"
    else
        echo "$resp"
    fi
}