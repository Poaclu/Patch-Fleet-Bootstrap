# Patch Bootstrap Installer

The universal unattended-upgrades bootstrapper — fully automatic vendor detection.

> One command → fully hardened unattended upgrades → fully fleet-ready.

---

## ✨ Features

- ✅ Fully auto-detect 3rd-party vendors installed on your system
- ✅ No manual vendor configuration needed
- ✅ Hardened unattended-upgrades configuration
- ✅ Fully universal webhook support (Discord, Notifiarr, Gotify, Shoutrrr, etc.)
- ✅ Daily healthcheck with webhook error alerts
- ✅ dpkg lockfile watchdog for stuck upgrades
- ✅ Auto-creates systemd unattended-upgrades timer if missing
- ✅ Cron + bcron support out of the box
- ✅ Fully fleet-safe and idempotent — safe to re-run any time

---

## 🚀 Usage

### Minimal install (fully offline mode — no webhook)

```bash
curl -fsSL https://raw.githubusercontent.com/Poaclu/Patch-Fleet-Bootstrap/main/patch-bootstrap.sh | sudo bash
```

✅ Automatically detects all APT vendors
✅ Builds correct unattended-upgrades config
✅ Runs fully locally with no webhook integration (See bellow for more info)
✅ Fully ready in seconds

### Full install with all options (webhook + timezone + disable auto-reboot)
```bash
curl -fsSL https://raw.githubusercontent.com/Poaclu/Patch-Fleet-Bootstrap/main/patch-bootstrap.sh | sudo bash -s -- --webhook "YOUR_WEBHOOK_URL" --timezone "Europe/Paris" --no-auto-reboot
```
✅ Enables deployment notifications & daily healthcheck error alerts
✅ Supports Discord, Notifiarr, Gotify, Shoutrrr, and other webhook systems (See bellow for formats, etc.)
✅ Timezone option (defaults to Europe/Paris)
✅ Auto-reboot enabled by default unless --no-auto-reboot is specified (usefull for certain servers)

## 🔧 Webhook Support

Compatible with any HTTP webhook system:

Provider | Format Example
-- | --
Discord | https://discord.com/api/webhooks/...
Notifiarr | generic://notifiarr.com/api/v1/notification/...
Gotify | https://gotify.example.com/...
Shoutrrr-compatible | Any valid URI
Custom | http://, https://, generic://, etc.

## 📦 Included components

- unattended-upgrades package management hardening
- Daily healthcheck with webhook error notification
- dpkg lock watchdog every 15 minutes
- Full cron + bcron support
- Automatic log rotation for healthcheck logs

## 🔧 Installed cron schedule

Task | Schedule
-- | --
Healthcheck | Daily at 07:00
Webhook alert | Daily at 07:15
APT lock watchdog | Every 15 minutes

## 🗄Logs

Log File | Description
-- | --
/var/log/unattended-upgrades/healthcheck.log | Daily upgrade check results
/var/log/unattended-upgrades/lockwatchdog.log | APT lock stuck detection
/var/log/patch-bootstrap.log | Bootstrap deployment logs

Logs are rotated daily with 7-day retention.

## ✅ Safe to re-run

Patch Bootstrap can safely be re-run at any time:
- Idempotent design
- Existing systemd timers, cron jobs and configuration are safely updated
- No duplication or conflicts

## 👷 Requirements
- Ubuntu 22.x, 24.x or Debian 11+
- sudo privileges
- Internet access for APT repositories
- Supports:
    - VPS providers (OVH, Hetzner, Scaleway, etc.)
    - Bare metal servers
    - LXC / Proxmox
    - Docker hosts
    - Homelab

## 🔒 Security
- No credentials stored inside the script.
- Webhook URL provided only at runtime.

## 🚀 Why Fully Automatic?
- Automatically adapts to your installed APT vendor sources
- No need to track vendor lists manually
- Fully self-maintaining for homelabs, production, or fleet deployment
- Future-proof for any new repositories you add

