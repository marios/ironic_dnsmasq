ironic_dnsmasq
==============


Do not under any circumstances run this code, it will ruin your life. Caveat emptor.

Get the code:

        git clone https://github.com/marios/ironic_dnsmasq.git
        cd ironic_dnsmasq

Edit the configuration to your needs - there are 2 parts:

        1. The dnsmasq configuration - IP range, PXE options:
        vim example_dnsmasq_conf

        2. The config for this script at ironic_dnsmasq_conf
        This file _must_ be kept in the same location that ironic_dnsmasq.sh
        is invoked from (it is sourced to set the configuration for the script)

Run discovery dnsmasq:

        ./ironic_dnsmasq.sh

Kill discovery dnsmasq:

        cd ironic_dnsmasq
        sed -i 's/RUN_DISCOVERY=True/RUN_DISCOVERY=False/g' ironic_dnsmasq_conf

