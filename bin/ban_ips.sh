#!/usr/bin/env bash
set -u

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/config/healer.conf"

mkdir -p "$BASE_DIR/logs"
LOG_FILE="$BASE_DIR/logs/ban.log"
AUTH_LOG="${AUTH_LOG:-/var/log/auth.log}"
THRESHOLD="${BAN_THRESHOLD:-5}"
WHITELIST="127.0.0.1"

log() { echo "$(date '+%F %T') [$1] $2" | tee -a "$LOG_FILE"; }

# Create the firewall table, blacklist set and drop rule (only once)
if ! nft list table inet healer > /dev/null 2>&1; then
  nft add table inet healer
  nft add set inet healer blacklist '{ type ipv4_addr; }'
  nft add chain inet healer input '{ type filter hook input priority 0; policy accept; }'
  nft add rule inet healer input ip saddr @blacklist drop
  log INFO "Firewall table created"
fi

# Count failed SSH passwords per IP, ban the ones at or over the threshold
grep -oP 'Failed password .* from \K[0-9]+(\.[0-9]+){3}' "$AUTH_LOG" 2>/dev/null \
  | sort | uniq -c \
  | while read -r count ip; do
      [ "$count" -lt "$THRESHOLD" ] && continue
      [ "$ip" = "$WHITELIST" ] && continue
      if nft list set inet healer blacklist | grep -qw "$ip"; then
        continue
      fi
      nft add element inet healer blacklist "{ $ip }"
      log WARN "BANNED $ip ($count failed logins)"
    done
