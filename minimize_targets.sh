#!/bin/bash
SCRIPT="$(basename $0 | sed 's/\..*$//')"
#CONF="${SCRIPT}.conf"
TMPFILE="$(mktemp XXXXXXX || exit 1)"
OUTPUT="${SCRIPT}.hosts"

touch "$OUTPUT" &>/dev/null || \
	{ echo "[-] Failed to write ${OUTPUT}. Aborted" >&2; exit 1; }

TARGETRANGE="${1:-172.20.23.0/24}"
shift
TARGETDESCR="${@:-Some unnamed network $(date '+%F %R') $(printf '%X' $(date '+%s%N'))}"

if [ -r "$TARGETRANGE" ]; then
	echo "[+] Found file $TARGETRANGE"
	grep -v '^#' "$TARGETRANGE" | grep -v '^[[:space:]]*$' | while read targetrange targetds
	do
		[ "x${targetrange}x" = "xx" ] && \
			continue
		#targetname="${targetds:-Some unnamed network $(date '+%F %R') $(printf '%X' $(date '+%s%N'))}"
		echo "[+] Scanning for target hosts in \"$targetrange\"..."
		nmap --min-rate 5000 -sn --open -n -oX "${TMPFILE}" --defeat-rst-ratelimit --defeat-rst-ratelimit --disable-arp-ping -PS21,22,23,25,53,80,110,111,135,139,143,443,445,993,995,1723,3306,3389,5900,8080 "$targetrange"
		sleep 5
		if [ -r "${TMPFILE}" ]; then
			cat "${TMPFILE}" | xml_pp | grep -A 1 'state="up"' | grep 'address addr' | sed 's/^.*address addr="\([0-9\.]*\)" addrtype=.*$/\1/' >> "${OUTPUT}"
		else
			echo "[-] ${TMPFILE} not readable. No results to add to ${OUTPUT}. Skipping"
		fi
		rm -f "${TMPFILE}" &>/dev/null
	done
	cp "$OUTPUT" "${TARGETRANGE}.new"
	echo "[+] Copied results from $OUTPUT to ${TARGETRANGE}.new"
else
	echo "[+] Scanning for target hosts in \"$TARGETRANGE\"..."
	nmap --min-rate 5000 -sn --open -n -oX "${TMPFILE}" --defeat-rst-ratelimit --defeat-rst-ratelimit --disable-arp-ping -PS21,22,23,25,53,80,110,111,135,139,143,443,445,993,995,1723,3306,3389,5900,8080 "$TARGETRANGE"
	sleep 5
	if [ -r "${TMPFILE}" ]; then
		cat "${TMPFILE}" | xml_pp | grep -A 1 'state="up"' | grep 'address addr' | sed 's/^.*address addr="\([0-9\.]*\)" addrtype=.*$/\1/' >> "${OUTPUT}"
	else
		echo "[-] ${TMPFILE} not readable. No results to add to ${OUTPUT}. Skipping"
	fi
	echo "[+] Results are in $OUTPUT"
fi
rm -f "$TMPFILE"
echo "[+] Done."



