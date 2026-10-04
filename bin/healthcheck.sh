#!/usr/bin/env bash
set -u

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/config/healer.conf"

mkdir -p "$BASE_DIR/logs"
LOG_FILE="$BASE_DIR/logs/health.log"
FAILED_FILE="$BASE_DIR/logs/failed_services.txt"

log() { echo "$(date '+%F %T') [$1] $2" | tee -a "$LOG_FILE"; }

score=100
: > "$FAILED_FILE"

# ---- CPU usage (sampled over 1 second from /proc/stat) ----
read -r _ u1 n1 s1 i1 w1 q1 sq1 _ < /proc/stat
sleep 1
read -r _ u2 n2 s2 i2 w2 q2 sq2 _ < /proc/stat
idle=$(( (i2 + w2) - (i1 + w1) ))
total=$(( (u2+n2+s2+i2+w2+q2+sq2) - (u1+n1+s1+i1+w1+q1+sq1) ))
cpu=0
[ "$total" -gt 0 ] && cpu=$(( 100 * (total - idle) / total ))

# ---- Memory usage ----
mem=$(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {printf "%d", (t-a)*100/t}' /proc/meminfo)

# ---- Disk usage of / ----
disk=$(df / --output=pcent | tail -1 | tr -dc '0-9')

# ---- Evaluate resources ----
if [ "$cpu" -ge "$CPU_LIMIT" ]; then
  log WARN "CPU high: ${cpu}%"; score=$((score - 20))
fi
if [ "$mem" -ge "$MEM_LIMIT" ]; then
  log WARN "Memory high: ${mem}%"; score=$((score - 20))
fi
if [ "$disk" -ge "$DISK_LIMIT" ]; then
  log WARN "Disk high: ${disk}%"; score=$((score - 20))
fi

# ---- Check services ----
for svc in $SERVICES; do
  if ! systemctl is-active --quiet "$svc"; then
    log ERROR "Service down: $svc"
    echo "$svc" >> "$FAILED_FILE"
    score=$((score - 20))
  fi
done

[ "$score" -lt 0 ] && score=0

log INFO "cpu=${cpu}% mem=${mem}% disk=${disk}% score=${score}/100"

# Exit code 1 if anything is wrong, so heal.sh can react to it
[ "$score" -eq 100 ] && exit 0 || exit 1
