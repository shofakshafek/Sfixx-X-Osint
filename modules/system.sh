#!/usr/bin/env bash
# System & network information

system_main() {
    log_info "System Information"
    echo "  OS        : $(uname -o 2>/dev/null || uname -s)"
    echo "  Kernel    : $(uname -r)"
    echo "  Arch      : $(uname -m)"
    echo "  Hostname  : $(hostname 2>/dev/null)"
    echo "  Uptime    : $(uptime -p 2>/dev/null || uptime)"
    echo "  Shell     : ${SHELL:-unknown}"
    echo "  User      : $(whoami 2>/dev/null)"
    echo

    log_info "Network Interfaces"
    if command -v ip >/dev/null 2>&1; then
        ip -brief addr 2>/dev/null | sed 's/^/  /' \
            || ip addr 2>/dev/null | grep -E "inet |inet6 " | sed 's/^/  /'
    elif command -v ifconfig >/dev/null 2>&1; then
        ifconfig 2>/dev/null | grep -E "inet |inet6 " | sed 's/^/  /'
    else
        echo "  (ip / ifconfig tidak tersedia)"
    fi
    echo

    log_info "Public IP"
    local pub
    pub=$(curl -s --max-time "${TIMEOUT:-10}" https://ifconfig.me 2>/dev/null)
    if [ -n "$pub" ]; then
        echo "  $pub"
    else
        log_warn "Tidak bisa mengambil public IP."
    fi
    echo

    log_done "System info selesai."
}