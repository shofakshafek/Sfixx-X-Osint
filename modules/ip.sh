#!/usr/bin/env bash
# IP information via ipinfo.io (public API)

ip_main() {
    local target="$1"
    if [ -z "$target" ]; then
        log_err "IP / domain wajib diisi."
        return 1
    fi

    if ! check_internet; then
        log_err "Tidak ada koneksi internet."
        return 1
    fi

    # Jika bukan IPv4, coba resolve sebagai domain
    if ! [[ "$target" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
        log_info "Bukan IPv4, mencoba resolve '$target'..."
        local resolved=""
        if command -v getent >/dev/null 2>&1; then
            resolved=$(getent hosts "$target" 2>/dev/null | awk '{print $1; exit}')
        fi
        if [ -z "$resolved" ] && command -v nslookup >/dev/null 2>&1; then
            resolved=$(nslookup "$target" 2>/dev/null \
                | awk '/^Address: /{print $2; exit}')
        fi
        if [ -z "$resolved" ] && command -v dig >/dev/null 2>&1; then
            resolved=$(dig +short "$target" A 2>/dev/null | head -n1)
        fi
        if [ -z "$resolved" ]; then
            log_err "Gagal resolve '$target'."
            return 1
        fi
        log_ok "Resolved: $resolved"
        target="$resolved"
    fi

    # Validasi range IP
    local ip="$target"
    local IFS='.'
    # shellcheck disable=SC2206
    local octets=($ip)
    for o in "${octets[@]}"; do
        if ! [[ "$o" =~ ^[0-9]+$ ]] || [ "$o" -lt 0 ] || [ "$o" -gt 255 ]; then
            log_err "IP tidak valid: $ip"
            return 1
        fi
    done

    log_info "Mengambil informasi untuk IP: ${C_YELLOW}$ip${C_RESET}"
    echo

    local resp
    resp=$(curl -s --max-time "${TIMEOUT:-10}" "https://ipinfo.io/$ip/json")
    if [ -z "$resp" ]; then
        log_err "Sumber data tidak tersedia (ipinfo.io)."
        return 1
    fi
    if command -v python3 >/dev/null 2>&1; then
        echo "$resp" | python3 -m json.tool 2>/dev/null || echo "$resp"
    else
        echo "$resp"
    fi
}