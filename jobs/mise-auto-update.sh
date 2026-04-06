#!/bin/bash
set -uo pipefail

SELF_UPDATE_STATUS=0
UPGRADE_STATUS=0

# mise global update
if mise self-update; then
    echo "mise self-update success" >> /var/log/mise-update.log
else
    SELF_UPDATE_STATUS=1
fi

# mise upgrade (all tools)
if mise upgrade --yes; then
    echo "mise upgrade success" >> /var/log/mise-update.log
else
    UPGRADE_STATUS=1
fi

TIMESTAMP=\$(date "+%Y-%m-%d %H:%M:%S")

if [ \$SELF_UPDATE_STATUS -eq 0 ] && [ \$UPGRADE_STATUS -eq 0 ]; then
    MSG="🚀 mise auto-update was successful: \$TIMESTAMP"
    echo "\$MSG" >> /var/log/mise-update.log
    echo "\$MSG" | wall 2>/dev/null || true
else
    MSG="mise update has warnings/errors: \$TIMESTAMP"
    echo "\$MSG" >> /var/log/mise-update.log
    echo -e "\a\$MSG\nPlease check /var/log/mise-update.log" | wall 2>/dev/null || true
fi

truncate -s 50K /var/log/mise-update.log

