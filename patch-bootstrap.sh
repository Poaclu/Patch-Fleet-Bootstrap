#!/bin/bash

# Patch Fleet Bootstrap Installer v1.3-Public

set -e

# Default timezone
TIMEZONE="Europe/Paris"
WEBHOOK_URL=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --webhook) WEBHOOK_URL="$2"; shift ;;
        --timezone) TIMEZONE="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Require webhook param
if [[ -z "$WEBHOOK_URL" ]]; then
    echo "Error: --webhook is required"
    exit 1
fi

# Deployment start notification
curl -H "Content-Type: application/json" \
  -X POST \
  -d "{\"content\": \"🚀 Patch Fleet Bootstrap started on $(hostname)\"}" \
  $WEBHOOK_URL

LOGFILE="/var/log/patch-bootstrap.log"
mkdir -p "$(dirname $LOGFILE)"
touch $LOGFILE

echo "$(date) - Starting bootstrap on $(hostname)" | tee -a $LOGFILE

# Set timezone
timedatectl set-timezone "$TIMEZONE"

# Install unattended-upgrades
apt update && apt install -y unattended-upgrades apt-listchanges

# Configure unattended-upgrades
cat << 'EOF' > /etc/apt/apt.conf.d/50unattended-upgrades
Unattended-Upgrade::Origins-Pattern {
        "origin=Ubuntu,codename=${distro_codename}";
        "origin=Ubuntu,codename=${distro_codename}-security";
        "origin=Ubuntu,codename=${distro_codename}-updates";
};

Unattended-Upgrade::Package-Blacklist {};
Unattended-Upgrade::DevRelease "auto";
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::InstallOnShutdown "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "04:00";
Unattended-Upgrade::Verbose "true";
Unattended-Upgrade::Allow-downgrade "false";
Unattended-Upgrade::Allow-APT-Mark-Fallback "true";
EOF

cat << 'EOF' > /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Verbose "1";
EOF

# Install Healthcheck Script
cat << 'EOF' > /usr/local/bin/uu-daily-healthcheck
#!/bin/bash
LOGFILE="/var/log/unattended-upgrades/healthcheck.log"
TMPFILE=$(mktemp)
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

echo "[$TIMESTAMP] Starting unattended-upgrades daily check" > $TMPFILE
unattended-upgrade --dry-run --debug >> $TMPFILE 2>&1

if grep -qi "error" $TMPFILE || grep -qi "not allowed" $TMPFILE; then
    echo "[$TIMESTAMP] PROBLEM detected in unattended-upgrades!" >> $TMPFILE
else
    echo "[$TIMESTAMP] All good." >> $TMPFILE
fi

cat $TMPFILE >> $LOGFILE
rm $TMPFILE
EOF

chmod +x /usr/local/bin/uu-daily-healthcheck

# Install Discord Alert Script (uses argument)
cat << EOF > /usr/local/bin/uu-discord-alert
#!/bin/bash
WEBHOOK_URL="$WEBHOOK_URL"
TMPFILE=\$(mktemp)
TIMESTAMP=\$(date "+%Y-%m-%d %H:%M:%S")

unattended-upgrade --dry-run --debug > \$TMPFILE 2>&1

if grep -i "error" \$TMPFILE | grep -v "ErrorText: ''"; then
    MSG="⚠️ [\$TIMESTAMP] Unattended-Upgrades ERROR Detected on \$(hostname)"
    curl -H "Content-Type: application/json" -X POST -d "{\\"content\\": \\"\$MSG\\"}" \$WEBHOOK_URL
else
    echo "[\$TIMESTAMP] No errors detected, all good."
fi

rm \$TMPFILE
EOF

chmod +x /usr/local/bin/uu-discord-alert

# Install APT Lock Watchdog
cat << 'EOF' > /usr/local/bin/apt-lock-watchdog
#!/bin/bash
if fuser /var/lib/dpkg/lock >/dev/null 2>&1; then
  echo "$(date): dpkg lock held! Possible stuck upgrade!" >> /var/log/unattended-upgrades/lockwatchdog.log
fi
EOF

chmod +x /usr/local/bin/apt-lock-watchdog

# Setup logrotate
cat << 'EOF' > /etc/logrotate.d/unattended-upgrades-healthcheck
/var/log/unattended-upgrades/healthcheck.log {
    rotate 7
    daily
    compress
    missingok
    notifempty
}

/var/log/unattended-upgrades/lockwatchdog.log {
    rotate 7
    daily
    compress
    missingok
    notifempty
}
EOF

# Setup systemd unattended-upgrades.timer if missing
if [ ! -f /etc/systemd/system/unattended-upgrades.timer ]; then
  echo "Systemd timer not found — creating custom unattended-upgrades timer/service."

  cat << 'EOF' > /etc/systemd/system/unattended-upgrades.service
[Unit]
Description=Run Unattended Upgrades
Documentation=man:unattended-upgrade(8)

[Service]
Type=oneshot
ExecStart=/usr/bin/unattended-upgrade
EOF

  cat << 'EOF' > /etc/systemd/system/unattended-upgrades.timer
[Unit]
Description=Unattended Upgrades
Documentation=man:unattended-upgrade(8)

[Timer]
OnCalendar=03:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

  systemctl daemon-reload
  systemctl enable unattended-upgrades.timer
  systemctl start unattended-upgrades.timer
else
  echo "Systemd unattended-upgrades.timer already exists, skipping creation."
  systemctl enable unattended-upgrades.timer
  systemctl start unattended-upgrades.timer
fi

# Universal crontab install (bcron or standard cron)
if command -v bcrontab >/dev/null 2>&1; then
  echo "bcron detected, writing crontab directly..."

  cat <<EOF > /tmp/patch-crontab
0 7 * * * /usr/local/bin/uu-daily-healthcheck
15 7 * * * /usr/local/bin/uu-discord-alert
*/15 * * * * /usr/local/bin/apt-lock-watchdog
EOF

  bcrontab /tmp/patch-crontab
  rm /tmp/patch-crontab

else
  echo "Standard crontab detected, appending via crontab -l..."

  (crontab -l 2>/dev/null; echo "0 7 * * * /usr/local/bin/uu-daily-healthcheck") | crontab -
  (crontab -l 2>/dev/null; echo "15 7 * * * /usr/local/bin/uu-discord-alert") | crontab -
  (crontab -l 2>/dev/null; echo "*/15 * * * * /usr/local/bin/apt-lock-watchdog") | crontab -
fi

# Deployment finish notification
curl -H "Content-Type: application/json" \
  -X POST \
  -d "{\"content\": \"✅ Patch Fleet Bootstrap completed on $(hostname)\"}" \
  $WEBHOOK_URL

echo "$(date) - Bootstrap completed successfully on $(hostname)" | tee -a $LOGFILE

