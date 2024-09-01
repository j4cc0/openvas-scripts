#!/bin/bash

QUIET="$1" # Use --quiet to disable output
SYNC="nvt gvmd-data scap cert notus nasl report-format scan-config port-list"

tell() {
	if [ "x${QUIET}x" = "xx" ]; then
		echo "[+] $@"
	fi
}

for sync in $SYNC
do
	tell "Updating OpenVAS $sync"
	greenbone-feed-sync --user _gvm --group _gvm $QUIET --type "$sync" || \
		tell "OpenVAS $sync feed had no clean exit. Please check. Skipping...."
done

# -- FIX UPS

# Ownership of plugins
tell "Fixing up ownership of plugins"
chown -R _gvm:_gvm /var/lib/openvas/plugins &>/dev/null

# Ownership of feed
tell "Fixing up ownership of feed"
UUID="$(sudo -u _gvm gvmd --get-users --verbose | awk '/^admin/ {print $NF}' | head -n 1)"
sudo -u _gvm gvmd --modify-setting 78eceaec-3385-11ea-b237-28d24461215b --value "$UUID"

tell "Rebuilding gvmd"
# gvmd needs a different? path to the ospd socket to be able to rebuild
( cd /run/ospd && ln -s ospd.sock ospd-openvas.sock ) &>/dev/null
# Rebuild everthing
sudo -u _gvm gvmd --rebuild --verbose 

tell "Done"

