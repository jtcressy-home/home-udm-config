#!/bin/sh
RULE_PRIORITY="5225"

function getDefaultTable() {
        /sbin/ip rule list priority 32766 | cut -d " " -f 4
}

function updateTailscaleRule() {
        /sbin/ip rule del priority $RULE_PRIORITY
        /sbin/ip rule add priority $RULE_PRIORITY from all fwmark 0x80000 lookup $1
}

echo Routing table with default route is $(getDefaultTable)
updateTailscaleRule $(getDefaultTable)

tail -Fn 0  /var/log/messages | while read line; do
        table=`echo $line | grep -e "ubios-udapi-server: wanFailover"`
        if [[ "$table" != ""  ]]
        then
                echo Detected WAN failover: Routing table with default route is $(getDefaultTable) now, adjusting rule >> /var/log/messages
                updateTailscaleRule $(getDefaultTable)
        fi
done