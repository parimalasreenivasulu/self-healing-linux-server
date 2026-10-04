#!/usr/bin/env bash
# Randomly breaks one thing. Run with sudo.
set -u
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/config/healer.conf"

pick=$((RANDOM % 2))
if [ "$pick" -eq 0 ]; then
  svcs=($SERVICES)
  svc="${svcs[RANDOM % ${#svcs[@]}]}"
  echo "CHAOS: stopping $svc"
  systemctl stop "$svc"
else
  echo "CHAOS: burning CPU for 40 seconds"
  for i in $(seq "$(nproc)"); do timeout 40 sh -c 'while :; do :; done' & done
  wait
fi
