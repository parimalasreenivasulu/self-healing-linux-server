# Self-Healing Linux Server

A Linux server that monitors itself, detects failures, and repairs them automatically.
Built with Bash, systemd and nftables on Ubuntu (WSL2).

## Features

- Monitors CPU, memory, disk usage and service status
- Calculates a health score from 0 to 100
- Automatically restarts crashed services (nginx, ssh)
- Blocks IPs with repeated failed SSH logins using an nftables blacklist
- Runs automatically through systemd timers
- Logs every check, repair and ban


## Project structure

    bin/healthcheck.sh    checks resources and services, writes the health score
    bin/heal.sh           restarts failed services and confirms recovery
    bin/ban_ips.sh        bans IPs with too many failed SSH logins
    config/healer.conf    thresholds and monitored services
    systemd/              healer and banner service and timer files
    logs/                 runtime logs (not committed)

## How it works

1. healer.timer starts healer.service every 30 seconds, which runs heal.sh.
2. heal.sh runs healthcheck.sh and restarts any service that is down.
3. banner.timer runs ban_ips.sh every minute, which reads /var/log/auth.log
   and adds repeat offenders to the nftables blacklist.

## Setup

    sudo apt install -y nginx openssh-server nftables
    chmod +x bin/*.sh
    sudo cp systemd/*.service systemd/*.timer /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable --now healer.timer banner.timer

Edit the ExecStart paths in the service files to match where you cloned the project.

## Demo

    sudo systemctl stop nginx
    tail -f logs/heal.log

Within 30 seconds the log shows nginx restarted and recovered.

## Roadmap

- [x] Health check and health score
- [x] Automatic service recovery
- [x] systemd timers
- [x] SSH brute-force IP blocker
- [x] Telegram alerts
- [x] Live dashboard
- [x] Chaos testing script
- [x] Daily incident report
