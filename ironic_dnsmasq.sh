#!/bin/bash
# source conf_file
# start dnsmasq based on conf
# loop while true
# get list of ironic ports. if change, add entry to hosts file, sighup.

set -e

source ironic_dnsmasq_conf

# rudimentary logging/debug. You can change 'echo' to whatever
function debug_msg {
    if [ $debug -eq 1 ]; then
        echo "DEBUG: An Ironic dnsmasq `date`: $1"
    fi
}

function refresh_node_list() {
    node_list=`ironic node-list --maintenance False | awk '/ .*-.* /{print $2}' `
    debug_msg "Refreshed node list: ${node_list[*]}"
}

function refresh_macs() {
    macs=()
    for node in $node_list ; do
        node_macs=`ironic node-port-list $node | awk '/..:..:..:/{print $4}'`
        for mac in $node_macs ; do
            macs+=("$mac")
        done
    done
    debug_msg "Got list of macs ${macs[*]}"
}

function update_host_file() {
    echo -n "" > $host_file
    for mac in "${macs[@]}"; do
        echo "$mac,ignore" >> $host_file
    done
    debug_msg "Updated host_file @ $host_file"
}

function sighup_dnsmasq {
    pid=$(cat $pid_file)
    debug_msg "Sending sighup to dnsmasq @ $pid"
    sudo kill -1 $pid
}

#get list of node MACs, write ignore file, start dnsmasq:
debug_msg "Starting... going to refresh nodes & MACs & write ignore file @ $host_file"
refresh_node_list
refresh_macs
update_host_file
dnsmasq_cmd="dnsmasq --no-hosts --no-resolv --strict-order --bind-interfaces
                --interface=$interface
                --conf-file=$dnsmasq_conf
                --dhcp-hostsfile=$host_file --leasefile-ro
                --pid-file=$pid_file"

debug_msg "Starting **SUDO** dnsmasq like: sudo $dnsmasq_cmd"
sudo $dnsmasq_cmd
export old_node_list=()
while [ $RUN_DISCOVERY == "True" ] ; do
    refresh_node_list
    if [[ "${node_list[@]}" = "${old_node_list[@]}" ]] ; then
        sleep $poll_interval;
        source ironic_dnsmasq_conf
    else
        refresh_macs
        update_host_file
        sighup_dnsmasq
        old_node_list=$node_list
    fi
done
#cleanup
pid=$(cat $pid_file)
debug_msg "Shutdown... kill -9 dnsmasq @ $pid"
sudo kill -9 $pid

