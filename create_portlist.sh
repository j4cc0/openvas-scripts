#!/bin/bash
SCRIPT="$(basename $0 | sed 's/\..*$//')"
CONF="${SCRIPT}.conf"

ADMINUSER="admin"
ADMINPASS='admin'

NMAPTOP1000PORTS="T:$(grep -v '^#' /usr/share/nmap/nmap-services 2>/dev/null | grep '[0-9]*/tcp' | sort -rk3 | head -n 1000 | awk '{print $2}' | sed 's/\/tcp//' | sort -nu | xargs echo | sed -e 's/ /,/g' -e 's/[^0-9,]//g')"

#PORTLISTNAME="${1:-Nmap Top 1000 TCP portlist on $(date '+%F %R')}"
PORTLISTNAME="${1:-Nmap Top 1000 TCP portlist}"
shift
PORTLIST="${@:-$NMAPTOP1000PORTS}"

if [ -r "$PORTLISTNAME" ]; then
	PORTLIST="$(cat $PORTLISTNAME)"
fi

[ -r "$CONF" ] && \
        . $CONF

XML="<create_port_list><name>${PORTLISTNAME}</name><comment>Created by $SCRIPT on $(date '+%F %R')</comment><port_range>${PORTLIST}</port_range></create_port_list>"
sudo -u _gvm gvm-cli --gmp-username="$ADMINUSER" --gmp-password="$ADMINPASS" socket --xml "$XML"


