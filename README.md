# Patch Fleet Bootstrap Installer

A fully universal, production-safe fleet bootstrapper for Ubuntu, Debian, VPS, homelab and internal servers.

Built for fully unattended server hardening, monitoring, and upgrade management — with webhook notifications compatible with Discord, Notifiarr, Gotify, Shoutrrr, and others.

---

## ✨ Features

- ✅ Hardened `unattended-upgrades` configuration
- ✅ Fully automatic package upgrades
- ✅ Auto creation of systemd timers if missing
- ✅ Healthcheck system
- ✅ Cron watchdog for stuck package locks
- ✅ Webhook alerts for upgrade failures
- ✅ Supports both `crontab` and `bcrontab` (bcron) systems
- ✅ Works on VPS, bare metal, LXC containers, cloud VMs, home servers, and more
- ✅ Fully safe to re-run anytime
- ✅ Simple CLI interface

---

## 🚀 Usage

### Quick one-liner installation

```bash
curl -s https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/patch-bootstrap/main/patch-bootstrap.sh | sudo bash -s -- --webhook "YOUR_WEBHOOK_URL"

