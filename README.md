# Patch Fleet Bootstrap Installer

**A simple universal server hardening bootstrap script.**

Deploys:
- Unattended-upgrades (hardened)
- Healthcheck system
- Discord failure notifications
- Cron watchdog
- Universal systemd compatibility (VPS + homelab safe)
- Fully portable across Ubuntu, Debian, VPS providers, Proxmox nodes, and more

## ✅ Usage

### ⚠️ Requirements:

- Ubuntu / Debian based systems
- `sudo` access

---

### 🖥 Install via GitHub (one-liner):

```bash
curl -s https://raw.githubusercontent.com/Poaclu/Patch-Fleet-Bootstrap/main/patch-bootstrap.sh | sudo bash -s -- --webhook "https://discord.com/api/webhooks/XXX/XXX"
