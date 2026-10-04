#!/usr/bin/env bash
# Sfixx x OSINT - Banner & color palette

# ANSI colors
export C_RESET='\033[0m'
export C_RED='\033[1;31m'
export C_GREEN='\033[1;32m'
export C_YELLOW='\033[1;33m'
export C_BLUE='\033[1;34m'
export C_MAGENTA='\033[1;35m'
export C_CYAN='\033[1;36m'
export C_WHITE='\033[1;37m'

show_banner() {
    echo -e "${C_CYAN}"
    cat << "EOF"
  ███████╗███████╗██╗██╗  ██╗██╗  ██╗
  ██╔════╝██╔════╝██║╚██╗██╔╝╚██╗██╔╝
  ███████╗█████╗  ██║ ╚███╔╝  ╚███╔╝
  ╚════██║██╔══╝  ██║ ██╔██╗  ██╔██╗
  ███████║██║     ██║██╔╝ ██╗██╔╝ ██╗
  ╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝
EOF
    echo -e "${C_RESET}"
    echo -e "        ${C_YELLOW}Sfixx x OSINT${C_RESET} ${C_WHITE}-${C_RESET} ${C_GREEN}Termux OSINT Toolkit${C_RESET}"
    echo -e "                    ${C_MAGENTA}Version ${VERSION}${C_RESET}"
    echo
}