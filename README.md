cd ~/self-healing-server
cat > README.md <<'EOF'
# Self-Healing Linux Server

A Linux server that monitors itself, detects failures, and repairs them automatically.
Built with Bash and systemd on Ubuntu (WSL2).

## Features

- Monitors CPU, memory, disk usage and service status
- Calculates a health score from 0 to 100
- Automatically restarts crashed services (nginx, ssh)
- Runs every 30 seconds using a systemd timer
- Logs every check and every repair

## Project structure

    bin/healthcheck.sh    checks resources and services, writes the health score
    bin/heal.sh           restarts failed services and confirms recovery
    config/healer.conf    thresholds and the list of monitored services
    systemd/              healer.service and healer.timer
    logs/                 health.log and heal.log (not committed)

## How it works

1. The systemd timer starts healer.service every 30 seconds.
2. heal.sh runs healthcheck.sh.
3. If a service is down, heal.sh restarts it and logs RECOVERED or FAILED.

## Setup

    sudo apt install -y nginx openssh-server
    chmod +x bin/*.sh
    sudo cp systemd/healer.* /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable --now healer.timer

Edit the ExecStart path in healer.service to match where you cloned the project.

## Demo

    sudo systemctl stop nginx
    tail -f logs/heal.log

Within 30 seconds the log shows nginx restarted and recovered.

## Roadmap

- [x] Health check and health score
- [x] Automatic service recovery
- [x] systemd timer
- [ ] SSH brute-force IP blocker
- [ ] Telegram alerts
- [ ] Live dashboard
- [ ] Chaos testing script
- [ ] Daily incident report
EOF
git add README.md
git commit -m "Add README"
git push
