#!/bin/bash
if apt-get update && apt-get dist-upgrade -y; then
    MSG="System auto-update success: \$(date)"
    echo "\$MSG" >> /var/log/sys-update.log
    echo "\$MSG" | wall 2>/dev/null || true
else
    MSG="ERROR in system auto-update: \$(date)"
    echo "\$MSG" >> /var/log/sys-update.log
    echo -e "\a\$MSG\nPlease check /var/log/sys-update.log" | wall 2>/dev/null || true
fi
truncate -s 50K /var/log/sys-update.log

