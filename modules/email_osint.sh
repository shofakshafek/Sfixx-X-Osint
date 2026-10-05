#!/usr/bin/env bash
# ================================================
# Sfixx x OSINT - Email OSINT Module
# Cek: validasi, domain, provider, MX, disposable, risk
# ================================================

email_osint_main() {
    local email="${1:-}"
    local API_URL="https://api.emailvalidation.io/v1/info?email="
    local DISPOSABLE_DOMAINS="tempmail.com 10minutemail.com guerrillamail.com mailinator.com yopmail.com throwawaymail.com sharklasers.com getnada.com dispostable.com temp-mail.org"

    if [ -z "$email" ]; then
        read -rp "$(echo -e "${C_YELLOW}Email: ${C_RESET}")" email
    fi
    email="$(echo "$email" | tr -d '[:space:]')"

    if [ -z "$email" ]; then
        log_err "Email tidak boleh kosong."
        return 1
    fi
    if ! [[ "$email" =~ ^[A-Za-z0-9._%+-]+@([A-Za-z0-9-]+\.)+[A-Za-z0-9-]{2,}$ ]]; then
        log_err "Format email tidak valid."
        return 1
    fi

    if ! check_internet; then
        log_err "Tidak ada koneksi internet."
        return 1
    fi

    local domain="${email##*@}"
    domain="${domain,,}"

    local provider
    provider="$(email_get_provider "$domain")"

    log_info "Menganalisis email: ${C_YELLOW}$email${C_RESET}"
    echo

    # ---------- Panggil API ----------
    local JSON="" is_valid="" disposable="" has_mx="" risk="" country=""
    if JSON="$(curl -fsS -m 15 -H 'Accept: application/json' "$API_URL$email" 2>/dev/null)" \
        && [ -n "$JSON" ]; then
        is_valid="$(email_json_get format_valid)"
        is_valid="${is_valid:-false}"
        disposable="$(email_json_get disposable)"
        disposable="${disposable:-false}"
        has_mx="$(email_json_get mx_found)"
        has_mx="${has_mx:-false}"
        risk="$(email_json_get risk)"
        country="$(email_json_get domain_country)"
        [ "$country" = "null" ] && country=""
        if [ -z "$risk" ] || [ "$risk" = "null" ]; then
            [ "$disposable" = "true" ] && risk="High" || risk="Low"
        fi
    else
        log_warn "API emailvalidation gagal, memakai mode offline."
        is_valid="true"
        disposable="false"
        country=""
        for d in $DISPOSABLE_DOMAINS; do
            [ "$domain" = "$d" ] && disposable="true"
        done
        if [ "$disposable" = "true" ]; then
            has_mx="false"; risk="High"
        else
            has_mx="true";  risk="Low"
        fi
        # Cek MX real pakai dig kalau ada
        if command -v dig >/dev/null 2>&1; then
            local mx_out
            mx_out="$(dig +short MX "$domain" 2>/dev/null)"
            if [ -n "$mx_out" ]; then
                has_mx="true"
                echo -e "${C_CYAN}MX Records (via dig):${C_RESET}"
                echo "$mx_out" | sed 's/^/  /'
                echo
            fi
        fi
    fi

    # ---------- Output utama ----------
    if [ "$is_valid" = "true" ]; then
        echo -e "${C_GREEN}[v] $email (Valid)${C_RESET}"
    else
        echo -e "${C_RED}[x] $email (Invalid)${C_RESET}"
    fi

    email_row "Domain"      "$domain"        "$C_WHITE"
    email_row "Provider"    "$provider"      "$C_WHITE"

    if [ "$has_mx" = "true" ]; then
        email_row "MX Record"   "Tersedia"           "$C_GREEN"
    else
        email_row "MX Record"   "Tidak Tersedia"     "$C_YELLOW"
    fi

    if [ "$disposable" = "true" ]; then
        email_row "Disposable"  "Ya (Temporary Email)" "$C_RED"
    else
        email_row "Disposable"  "Tidak"               "$C_GREEN"
    fi

    local c="$C_GREEN"
    case "$risk" in
        High)   c="$C_RED" ;;
        Medium) c="$C_YELLOW" ;;
    esac
    email_row "Risk Level"  "$risk"     "$c"

    [ -n "$country" ] && email_row "Country" "$country" "$C_WHITE"

    # ---------- Kesimpulan ----------
    echo
    if [ "$is_valid" != "true" ]; then
        echo "Email ini tidak valid atau tidak memiliki MX record."
    elif [ "$disposable" = "true" ]; then
        echo "Email ini bersifat sementara (disposable). Hati-hati untuk verifikasi akun."
    else
        echo "Email valid dengan MX record. Cocok untuk komunikasi bisnis."
    fi

    # ---------- HIBP (opsional) ----------
    if [ -n "${HIBP_API_KEY:-}" ]; then
        echo
        echo -e "${C_CYAN}--- Cek Data Breach (HIBP) ---${C_RESET}"
        local hibp_code hibp_body
        hibp_body="$(curl -fsS -m 15 \
            -H "hibp-api-key: $HIBP_API_KEY" \
            -H "User-Agent: Sfixx-OSINT" \
            "https://haveibeenpwned.com/api/v3/breachedaccount/$email?truncateResponse=true" \
            2>/dev/null)"
        hibp_code=$?
        if [ $hibp_code -eq 0 ] && [ -n "$hibp_body" ]; then
            local count
            count="$(echo "$hibp_body" | grep -o '"Name"' | wc -l)"
            echo -e "  ${C_RED}[!]${C_RESET} Ditemukan di $count breach publik."
            echo "$hibp_body" | grep -o '"Name":"[^"]*"' \
                | sed 's/"Name":"/  - /; s/"$//'
        else
            echo -e "  ${C_GREEN}[v]${C_RESET} Tidak ditemukan di breach publik (atau rate-limit)."
        fi
    fi

    echo
    log_done "Selesai."
}

# ---------- Helper ----------
email_get_provider() {
    case "$1" in
        *gmail*|*googlemail*)         echo "Google (Gmail)" ;;
        *yahoo*)                      echo "Yahoo" ;;
        *outlook*|*hotmail*|*live*)   echo "Microsoft (Outlook)" ;;
        *proton*|*pm.me*)             echo "ProtonMail" ;;
        *icloud*|*me.com*|*mac.com*)  echo "Apple (iCloud)" ;;
        *zoho*)                       echo "Zoho Mail" ;;
        *gmx*)                        echo "GMX Mail" ;;
        *yandex*)                     echo "Yandex Mail" ;;
        *)                            echo "Custom Domain" ;;
    esac
}

email_json_get() {
    grep -oE "\"$1\"[[:space:]]*:[[:space:]]*(\"[^\"]*\"|true|false|null|[0-9]+)" <<<"$JSON" \
        | head -1 | sed -E 's/^"[^"]*"[[:space:]]*:[[:space:]]*//; s/^"//; s/"$//'
}

email_row() {
    printf "  %-12s : %b%s%b\n" "$1" "$3" "$2" "$C_RESET"
}
