#!/usr/bin/env bash
# Subdomain discovery using certificate transparency (crt.sh)

subdomain_main() {
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

    if ! require_cmd python3; then
        log_err "Python3 wajib untuk parsing JSON."
        return 1
    fi

    log_info "Mencari subdomain untuk: ${C_YELLOW}$domain${C_RESET}"
    log_info "Sumber: crt.sh (Certificate Transparency)"
    echo

    local json
    json=$(curl -s --max-time 25 "https://crt.sh/?q=%25.$domain&output=json")

    if [ -z "$json" ] || [ "$json" = "[]" ]; then
        log_warn "Tidak ada hasil dari crt.sh."
        return 1
    fi

    echo "$json" | DOMAIN="$domain" python3 - << 'PYEOF'
import sys, json, os

domain = os.environ.get("DOMAIN", "").lower()
try:
    data = json.load(sys.stdin)
except Exception:
    print("Gagal parse JSON dari crt.sh.")
    sys.exit(0)

subs = set()
for item in data:
    name_value = str(item.get("name_value", ""))
    for name in name_value.split("\n"):
        name = name.strip().lower()
        if name.startswith("*."):
            name = name[2:]
        if name and (name == domain or name.endswith("." + domain)):
            subs.add(name)

if not subs:
    print("Tidak ada subdomain ditemukan.")
    sys.exit(0)

print(f"Ditemukan {len(subs)} subdomain unik:\n")
for s in sorted(subs):
    print("  " + s)
PYEOF

    echo
    log_done "Subdomain discovery selesai."
    log_warn "Data berasal dari Certificate Transparency, bukan scan aktif."
}