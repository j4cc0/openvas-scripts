#!/bin/bash
SCRIPT="$(basename $0 | sed 's/\..*$//')"
CONF="${SCRIPT}.conf"

TARGETRANGE="${1:-172.20.23.0/24}"
shift
TARGETDESCR="${@:-Some unnamed network $(date '+%F %R') $(printf '%X' $(date '+%s%N'))}"
ADMINUSER="admin"
ADMINPASS='admin'
PORTLISTNAME="All TCP and Nmap top 100 UDP"
CONFIGNAME="Full and fast"
SCANNERNAME="OpenVAS Default"

[ -r "$CONF" ] && \
	. $CONF

PORTLISTID=$(sudo -u _gvm gvm-cli --gmp-username="$ADMINUSER" --gmp-password="$ADMINPASS" socket --xml '<get_port_lists/>' | xml_pp | grep -B 4 "$PORTLISTNAME" | awk '/id=/ { print $NF }' | sed 's/^id="\(.*\)">.*$/\1/')
[ "x${PORTLISTID}x" = "xx" ] && \
	{ echo "[-] Failed to retrieve a portid matching \"$POSTLISTNAME\". Aborted" >&2; exit 1; }

CONFIGID=$(sudo -u _gvm gvm-cli --gmp-username="$ADMINUSER" --gmp-password="$ADMINPASS" socket --xml '<get_configs></get_configs>' | xml_pp | grep -B 4 "${CONFIGNAME}" | awk '/id=/ { print $NF }' | sed 's/^id="\(.*\)".*$/\1/')
[ "x${CONFIGID}x" = "xx" ] && \
	{ echo "[-] Failed to retreive a configid matching \"$CONFIGNAME\". Aborted" >&2; exit 1; }

SCANNERID=$(sudo -u _gvm gvm-cli --gmp-username="$ADMINUSER" --gmp-password="$ADMINPASS" socket --xml '<get_scanners></get_scanners>' | xml_pp | grep -B 4 "$SCANNERNAME" | awk '/id=/ { print $NF }' | sed 's/^id="\(.*\)".*$/\1/')
[ "x${SCANNERID}x" = "xx" ] && \
	{ echo "[-] Failed to retreive a scannerid matching \"$SCANNERNAME\". Aborted" >&2; exit 1; }

if [ -r "$TARGETRANGE" ]; then
	echo "[+] Found file $TARGETRANGE"
	grep -v '^#' "$TARGETRANGE" | grep -v '^[[:space:]]*$' | while read targetrange targetds
	do
		[ "x${targetrange}x" = "xx" ] && \
			continue
		targetname="${targetds:-Some unnamed network $(date '+%F %R') $(printf '%X' $(date '+%s%N'))}"
		echo "[+] Creating target \"$targetrange\" named as \"$targetname\"..."
		XML="<create_target><name>${targetname}</name><hosts>${targetrange}</hosts><port_list id=\"${PORTLISTID}\"></port_list></create_target>"
		cmd="sudo -u _gvm gvm-cli --gmp-username='$ADMINUSER' --gmp-password='$ADMINPASS' socket --xml '$XML' 2>&1 | xml_pp | grep 'OK, resource created' | awk '/id=/ { print $NF }' | sed 's/^.*id=\"\([0-9a-zA-Z\-]*\)\".*$/\1/'"
		targetid=$(eval "$cmd")
		if [ "x${targetid}x" = "xx" ]; then
			echo "[-] Something went wrong...." >&2
			sudo -u _gvm gvm-cli --gmp-username="$ADMINUSER" --gmp-password="$ADMINPASS" socket --xml "$XML" 2>&1
			exit 1
		fi
		taskname="Scan $targetrange"
		taskcomment="Scan $targetname"
		echo "[+] Creating task \"$taskname\"..."
		XML="<create_task><name>${taskname}</name><comment>${taskcomment}</comment><config id=\"${CONFIGID}\"/><target id=\"${targetid}\"/><scanner id=\"${SCANNERID}\"/></create_task>"
		sudo -u _gvm gvm-cli --gmp-username="$ADMINUSER" --gmp-password="$ADMINPASS" socket --xml "$XML"
	done
else
	echo "[+] Processing \"$TARGETRANGE\" named as \"$TARGETDESCR\"..."
	XML="<create_target><name>${TARGETDESCR}</name><hosts>${TARGETRANGE}</hosts><port_list id=\"${PORTLISTID}\"></port_list></create_target>"
	targetid=$(sudo -u _gvm gvm-cli --gmp-username="$ADMINUSER" --gmp-password="$ADMINPASS" socket --xml "$XML" 2>&1 | grep 'OK, resource created' | awk '/id=/ { print $NF }' | sed 's/^.*id="\([0-9a-zA-Z\-]*\)".*$/\1/')
	if [ "x${targetid}x" = "xx" ]; then
		echo "[-] Something went wrong...." >&2
		sudo -u _gvm gvm-cli --gmp-username="$ADMINUSER" --gmp-password="$ADMINPASS" socket --xml "$XML" 2>&1
		exit 1
	fi
	taskname="Scan $TARGETRANGE"
	taskcomment="Scan $TARGETDESCR"
	echo "[+] Creating task \"$taskname\"..."
	XML="<create_task><name>${taskname}</name><comment>${taskcomment}</comment><config id=\"${CONFIGID}\"/><target id=\"${targetid}\"/><scanner id=\"${SCANNERID}\"/></create_task>"
	sudo -u _gvm gvm-cli --gmp-username="$ADMINUSER" --gmp-password="$ADMINPASS" socket --xml "$XML"
fi

