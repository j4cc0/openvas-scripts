** Experimental code. This needs some love and care. **

Tested on kali linux. 
Install OpenVAS (packages and dependencies may follow, make sure to have some diskspace available)

	apt install gvm gvm-tools greenbone-security-assistent
	gvm-setup
	gvm-check-setup

Edit create_portlist.conf, then run

	./create_portlist.sh

Edit create_target.conf, then run

	./create_target.sh

Next, hop over to the webinterface (https://127.0.0.1:9392) and log in. Check if portlist and target are created. Inspect `openvas-feedsync.sh` as it contains fix-ups that might not be needed anymore. Then run

	./openvas-feedsync.sh

This may take a LONG time to complete. Don't be too surprized when synchronization leaves you with x day old updates (not current as you'd might expect).

