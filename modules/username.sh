#!/usr/bin/env bash
# Username search across public sites (HTTP status-based)

username_main() {
    local username="$1"
    if [ -z "$username" ]; then
        log_err "Username wajib diisi."
        return 1
    fi

    if ! check_internet; then
        log_err "Tidak ada koneksi internet."
        return 1
    fi

    log_info "Mencari username: ${C_YELLOW}$username${C_RESET}"
    echo

    # Format: "NamaSitus|URLTemplate"
    local sites=(
        "GitHub|https://github.com/%s"
        "GitLab|https://gitlab.com/%s"
        "Twitter/X|https://x.com/%s"
        "Instagram|https://www.instagram.com/%s/"
        "Reddit|https://www.reddit.com/user/%s"
        "TikTok|https://www.tiktok.com/@%s"
        "Medium|https://medium.com/@%s"
        "Pinterest|https://www.pinterest.com/%s/"
        "Telegram|https://t.me/%s"
        "YouTube|https://www.youtube.com/@%s"
        "Facebook|https://www.facebook.com/%s"
        "LinkedIn|https://www.linkedin.com/in/%s"
        "Steam|https://steamcommunity.com/id/%s"
        "Spotify|https://open.spotify.com/user/%s"
        "Patreon|https://www.patreon.com/%s"
        "Keybase|https://keybase.io/%s"
        "HackerNews|https://news.ycombinator.com/user?id=%s"
        "Twitch|https://www.twitch.tv/%s"
        "Vimeo|https://vimeo.com/%s"
        "SoundCloud|https://soundcloud.com/%s"
    )

    local found=0
    local total=0

    printf "%-14s %-8s %s\n" "SITE" "STATUS" "URL"
    printf '%.0s-' {1..62}; echo

    for entry in "${sites[@]}"; do
        local name="${entry%%|*}"
        local tmpl="${entry#*|}"
        local url
        # shellcheck disable=SC2059
        url=$(printf "$tmpl" "$username")
        total=$((total+1))

        local code
        code=$(curl -s -o /dev/null -w "%{http_code}" \
            -A "Mozilla/5.0 (Termux; Sfixx-OSINT)" \
            -L --max-time "${TIMEOUT:-10}" "$url" 2>/dev/null)

        if [ "$code" = "200" ]; then
            printf "${C_GREEN}%-14s %-8s %s${C_RESET}\n" "$name" "$code" "$url"
            found=$((found+1))
        else
            printf "%-14s %-8s %s\n" "$name" "${code:-ERR}" "$url"
        fi
    done

    printf '%.0s-' {1..62}; echo
    log_done "Ditemukan $found/$total kemungkinan match (berdasarkan HTTP 200)."
    log_warn "Hasil bisa false-positive/negative karena proteksi anti-bot."
}