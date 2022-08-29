#!/bin/sh
RULE_PRIORITY="5225"
INTERVAL="60s"

function getDefaultTable() {
        /sbin/ip rule list priority 32766 | cut -d " " -f 4
}

function updateTailscaleRule() {
        /sbin/ip rule del priority $RULE_PRIORITY
        /sbin/ip rule add priority $RULE_PRIORITY from all fwmark 0x80000 lookup $1
}

echo Routing table with default route is $(getDefaultTable)
updateTailscaleRule $(getDefaultTable)

until false; do
  echo Routing table with default route is $(getDefaultTable), updating rule $RULE_PRIORITY
  updateTailscaleRule $(getDefaultTable)
  echo Checking again in $INTERVAL
  sleep $INTERVAL
done

#tail -Fn 0  /var/log/messages | while read line; do
#        table=`echo $line | grep -e "ubios-udapi-server: wanFailover"`
#        if [[ "$table" != ""  ]]
#        then
#                echo Detected WAN failover: Routing table with default route is $(getDefaultTable) now, adjusting rule >> /var/log/messages
#                updateTailscaleRule $(getDefaultTable)
#        fi
#done