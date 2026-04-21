#!/bin/bash
# Linux User Management Script
# Author: José  Lemus  | LPIC-1

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

usage() {
    echo "Usage: $0 {create|delete|lock|unlock|audit|bulk-create} [options]"
    echo "  create <username> <group>  - Create user with group"
    echo "  delete <username>          - Delete user and home"
    echo "  lock <username>            - Lock user account"
    echo "  unlock <username>          - Unlock user account"
    echo "  audit                      - Full user audit report"
    echo "  bulk-create <csv-file>     - Create users from CSV"
}

create_user() {
    local user=$1 group=$2
    if id "$user" &>/dev/null; then
        echo -e "${RED}User $user already exists${NC}"; return 1
    fi
    groupadd -f "$group"
    useradd -m -g "$group" -s /bin/bash "$user"
    passwd_temp=$(openssl rand -base64 12)
    echo "$user:$passwd_temp" | chpasswd
    chage -d 0 "$user"  # Force password change
    echo -e "${GREEN}✅ Created: $user (group: $group) | Temp pass: $passwd_temp${NC}"
}

audit_users() {
    echo -e "${YELLOW}═══ USER AUDIT REPORT ═══${NC}"
    echo -e "Date: $(date)\n"
    echo "--- Active Users ---"
    awk -F: '$7 !~ /(nologin|false)/ && $3 >= 1000 {printf "  %-15s UID:%-5s Home:%-20s Shell:%s\n", $1,$3,$6,$7}' /etc/passwd
    echo -e "\n--- Locked Accounts ---"
    while IFS=: read -r user status; do
        [[ "$status" == "!" || "$status" == "*" ]] && echo "  🔒 $user"
    done < <(awk -F: '{print $1":"substr($2,1,1)}' /etc/shadow 2>/dev/null)
    echo -e "\n--- Users with sudo ---"
    grep -E '^[^#].*ALL=' /etc/sudoers /etc/sudoers.d/* 2>/dev/null | sed 's/^/  /'
    echo -e "\n--- Last 10 Logins ---"
    last -10 | head -12
}

case "$1" in
    create) create_user "$2" "$3" ;;
    delete) userdel -r "$2" 2>/dev/null && echo -e "${GREEN}Deleted: $2${NC}" ;;
    lock) usermod -L "$2" && echo -e "${YELLOW}Locked: $2${NC}" ;;
    unlock) usermod -U "$2" && echo -e "${GREEN}Unlocked: $2${NC}" ;;
    audit) audit_users ;;
    *) usage ;;
esac
