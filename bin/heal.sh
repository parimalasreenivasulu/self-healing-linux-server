#!/usr/bin/env bash
set -u

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$BASE_DIR/logs/heal.log"
FAILED_FILE="$BASE_DIR/logs/failed_services.txt"

log() { echo "$(date '+%F %T') [$1] $2" | tee -a "$LOG_FILE"; }

# Run the health check; exit code 0 means everything is fine
"$BASE_DIR/bin/healthcheck.sh" > /dev/null
if [ $? -eq 0 ]; then
  exit 0
fi

# Restart every service listed as failed
while read -r svc; do
  [ -z "$svc" ] && continue
  log WARN "Restarting $svc ..."
  if systemctl restart "$svc"; then
    sleep 2
    if systemctl is-active --quiet "$svc"; then
      log INFO "RECOVERED: $svc is running again"
    else
      log ERROR "FAILED to recover: $svc"
    fi
  else
    log ERROR "restart command failed for: $svc"
  fi
done < "$FAILED_FILE"
