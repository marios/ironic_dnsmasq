#!/bin/bash
# source conf_file
# start dnsmasq based on conf
# loop while true
# get list of ironic ports. if change, add entry to hosts file, sighup.

source discovery_dnsmasq_conf

# rudimentary logging/debug. You can change 'echo' to whatever
function debug_msg {
    if [ $debug -eq 1 ]; then 
        echo "DEBUG: An Ironic dnsmasq `date`: $1"
    fi
}

function refresh_macs() {
    new_macs=`ironic port-list | awk '/..:..:../{print $4}'`
}

function update_host_file() {
        echo -n "" > $host_file
        for mac in $new_macs; do
            echo "$mac,ignore" >> $host_file
	done
	pid=$(cat $pid_file)
	debug_msg "pid is $pid"
        kill -1 $pid
}

refresh_macs
dnsmasq_cmd="dnsmasq  --no-hosts --no-resolv --strict-order --bind-interfaces --interface=$interface --conf-file=$dnsmasq_conf --dhcp-hostsfile=$host_file --leasefile-ro --pid-file=$pid_file"
debug_msg "executing $dnsmasq_cmd";
$dnsmasq_cmd 
debug_msg "dnsmasq_pid @ `cat $pid_file`";
old_macs=()
while [ $RUN_DISCOVERY == "True" ] ; do
    refresh_macs
    if  [[ "${new_macs[@]}" = "${old_macs[@]}" ]] ; then
        debug_msg "MACS same, sleeping 10"
	sleep 10;
	source discovery_dnsmasq_conf
    else
	debug_msg "Rewriting hosts file, SIGHUP"
        update_host_file
	old_macs=$new_macs
   fi
done
#cleanup
pid=$(cat $pid_file)
debug_msg "Killing dnsmasq @ $pid"
kill -9 $pid
