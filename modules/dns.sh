#!/usr/bin/env bash
# DNS Lookup (A, AAAA, MX, NS, TXT, CNAME, SOA)

dns_main() {
    local domain="$1"
    if [ -z "$domain" ]; then
        log_err "Domain wajib diisi."
        return 1
    fi
    domain="${domain#http://}"
    domain="${domain#https://}"
    domain="${domain%%/*}"

    if ! check_internet; then
        log_err "Tidak ada koneksi internet."
        return 1
    fi

    local tool=""
    if command -v dig >/dev/null 2>&1; then
        tool="dig"
    elif command -v nslookup >/dev/null 2>&1; then
        tool="nslookup"
    elif command -v host >/dev/null 2>&1; then
        tool="host"
    else
        log_err "dnsutils belum terpasang. Jalankan: pkg install dnsutils"
        return 1
    fi

    log_info "DNS Lookup untuk: ${C_YELLOW}$domain${C_RESET} (via $tool)"
    echo

    local types=(A AAAA MX NS TXT CNAME SOA)
    for t in "${types[@]}"; do
        echo -e "${C_CYAN}── $t records ──${C_RESET}"
        case "$tool" in
            dig)
                local out
                out=$(dig +short "$domain" "$t" 2>/dev/null)
                if [ -z "$out" ]; then
                    echo "  (tidak ada)"
                else
                    echo "$out" | sed 's/^/  /'
                fi
                ;;
            nslookup)
                nslookup -type="$t" "$domain" 2>/dev/null \
                    | awk 'NR>3' | sed 's/^/  /'
                ;;
            host)
                host -t "$t" "$domain" 2>/dev/null | sed 's/^/  /'
                ;;
        esac
        echo
    done

    log_done "DNS lookup selesai."
}