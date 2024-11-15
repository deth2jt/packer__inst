#!/bin/bash -eux

echo '==> Removing Red Hat subscriptions'
subscription-manager remove --all
subscription-manager unregister
subscription-manager clean
echo "$SSH_USERNAME:$RHN_PASSWORD" | sudo chpasswd
echo '==> Subscriptions successfully removed'
# nmcli con add con-name my-eth1 ifname ens34 type ethernet ipv4.addresses "192.68.66.10/27" ipv4.gateway 192.68.66.30
# nmcli con mod my-eth1  ipv4.method manual
