#!/usr/bin/env bash
# Usage: alert.sh "message text"
ENV_FILE="${HEALER_ENV:-/home/parimparim/.config/healer/telegram.env}"
[ -f "$ENV_FILE" ] || { echo "No Telegram config at $ENV_FILE" >&2; exit 1; }
source "$ENV_FILE"

MSG="${1:-}"
[ -z "$MSG" ] && { echo "Usage: $0 \"message\"" >&2; exit 1; }

curl -s -m 10 -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
  --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
  --data-urlencode "text=[$(hostname)] ${MSG}" > /dev/null
