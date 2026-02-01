#!/bin/sh
DEBUG="${DEBUG:-0}"
INTERFACE=$(route | grep "default" | awk '{print $8}')
IP=$(ifconfig $INTERFACE | grep "inet " | cut -d: -f2 | awk '{print $1}')
LC_ALL=${LC_ALL:-"en_GB.UTF-8"}
TIMEZONE=${TIMEZONE:-"Europe/Brussels"}

debug() { [ "$DEBUG" = "1" ] && echo "[init] $*"; }

# Check Locale
CHECK=$(locale -a | grep ${LC_ALL} | wc -l)
if [ ${CHECK} == 1 ]; then
    debug "Locale current is: ${LC_ALL}"
    export LC_ALL
else 
    echo "Locale ${LC_ALL} not supported or not exist"
    echo "Locale availables:"
    locale -a
    echo ""
    echo "Locale current is en_GB.UTF-8"
fi

echo "#/bin/sh" >> /etc/profile.d/init.sh
echo "export LC_ALL=${LC_ALL}" >> /etc/profile.d/init.sh

chmod +x /etc/profile.d/init.sh

echo "export LC_ALL=${LC_ALL}" >> /root/.profile

# Check Timezone
CHECK==$(test -f /usr/share/zoneinfo/${TIMEZONE})
if [ $? == 0 ]; then
    debug "Timezone current is ${TIMEZONE}"
    cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
    export TIMEZONE
else 
    echo "Timezone ${TIMEZONE} not supported or not exist"
    echo "Timezone current is Europe/Brussels"
fi

# Network
debug "Interface ${INTERFACE}"
export INTERFACE

debug "IP ${IP}"
export IP
