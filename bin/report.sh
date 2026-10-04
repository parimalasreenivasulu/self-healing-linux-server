#!/usr/bin/env bash
set -u
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DAY="${1:-$(date +%F)}"
OUT="$BASE_DIR/reports/incident-$DAY.txt"
mkdir -p "$BASE_DIR/reports"

H="$BASE_DIR/logs/health.log"
R="$BASE_DIR/logs/heal.log"
B="$BASE_DIR/logs/ban.log"

count() { [ -f "$2" ] && grep "^$DAY" "$2" | grep -c "$1" || echo 0; }

{
  echo "INCIDENT REPORT for $DAY"
  echo "========================"
  echo "Health checks run:        $(count 'INFO\] cpu=' "$H")"
  echo "Service failures seen:    $(count 'Service down' "$H")"
  echo "Successful recoveries:    $(count 'RECOVERED' "$R")"
  echo "Failed recoveries:        $(count 'FAILED to recover' "$R")"
  echo "IPs banned:               $(count 'BANNED' "$B")"
  echo
  echo "--- Recoveries ---"
  [ -f "$R" ] && grep "^$DAY" "$R" | grep -E 'RECOVERED|FAILED' || echo "(none)"
  echo
  echo "--- Bans ---"
  [ -f "$B" ] && grep "^$DAY" "$B" | grep BANNED || echo "(none)"
  echo
  echo "--- Lowest health score ---"
  [ -f "$H" ] && grep "^$DAY" "$H" | grep -oP 'score=\K[0-9]+' | sort -n | head -1 || echo "n/a"
} > "$OUT"

cat "$OUT"
