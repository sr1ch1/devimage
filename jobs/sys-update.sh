#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
if apt-get update && apt-get -y -o Dpkg::Options::="--force-confold" dist-upgrade; then
    MSG="System auto-update success: $(date)"
    echo "$MSG" >> /var/log/sys-update.log
    echo "$MSG" | wall 2>/dev/null || true
else
    MSG="ERROR in system auto-update: $(date)"
    echo "$MSG" >> /var/log/sys-update.log
    echo -e "\a$MSG\nPlease check /var/log/sys-update.log" | wall 2>/dev/null || true
fi
if [ -f /var/log/sys-update.log ] && [ "$(stat -c%s /var/log/sys-update.log 2>/dev/null || echo 0)" -gt 51200 ]; then
    tail -c 50K /var/log/sys-update.log > /var/log/sys-update.log.tmp && mv /var/log/sys-update.log.tmp /var/log/sys-update.log
fi

