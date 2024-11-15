#!/bin/bash -eux

echo '==> Removing temporary files used to build box'
# Make sure udev doesn't block our network
if grep -q -i "release 6" /etc/redhat-release ; then
    rm -f /etc/udev/rules.d/70-persistent-net.rules
    mkdir /etc/udev/rules.d/70-persistent-net.rules
    rm /lib/udev/rules.d/75-persistent-net-generator.rules
fi
rm -rf /dev/.udev/
if [ -f /etc/sysconfig/network-scripts/ifcfg-eth0 ] ; then
    sed -i "/^HWADDR/d" /etc/sysconfig/network-scripts/ifcfg-eth0
    sed -i "/^UUID/d" /etc/sysconfig/network-scripts/ifcfg-eth0
fi

# new-style network device naming for centos7
if grep -q -i "release 7" /etc/redhat-release ; then
  # radio off & remove all interface configration
  nmcli radio all off
  /bin/systemctl stop NetworkManager.service
  for ifcfg in `ls /etc/sysconfig/network-scripts/ifcfg-* |grep -v ifcfg-lo` ; do
    rm -f $ifcfg
  done
  rm -rf /var/lib/NetworkManager/*

  echo "==> Setup /etc/rc.d/rc.local for CentOS7"
  cat <<_EOF_ | cat >> /etc/rc.d/rc.local
#BOXCUTTER-BEGIN
LANG=C
# delete all connection
for con in \`nmcli -t -f uuid con\`; do
  if [ "\$con" != "" ]; then
    nmcli con del \$con
  fi
done
# add gateway interface connection.
gwdev=\`nmcli dev | grep ethernet | egrep -v 'unmanaged' | head -n 1 | awk '{print \$1}'\`
if [ "\$gwdev" != "" ]; then
  nmcli c add type eth ifname \$gwdev con-name \$gwdev
fi
sed -i -e "/^#BOXCUTTER-BEGIN/,/^#BOXCUTTER-END/{s/^/# /}" /etc/rc.d/rc.local
chmod -x /etc/rc.d/rc.local
#BOXCUTTER-END
_EOF_
  chmod +x /etc/rc.d/rc.local
fi

DISK_USAGE_BEFORE_CLEANUP=$(df -h)

# Other locales will be removed from the VM
# UPDATE 10/14/2021 - Not so important to remove locales; had issue on rhel 8 so removed this code
# For RHEL possible to do this https://access.redhat.com/solutions/2208961
# Use `du -c --max-depth=1 /usr/share | sort -n` to find condidates for cleanup
#KEEP_LANGUAGE="en"
#echo "==> Remove unused locales"

# UPDATE 10/14/2021 - Removed; caused errors in RHEL 8 and unnecessary
# echo "==> Remove packages needed for building guest tools"
# yum -y remove gcc cpp libmpc mpfr kernel-devel kernel-headers perl

echo '==> Clean up yum cache of metadata and packages to save space'
yum -y clean all

echo "==> Clear core files"
rm -f /core*

echo "==> Remote temporary files used to build box"
rm -rf /tmp/*

echo "==> Rebuild RPM DB"
rpmdb --rebuilddb
rm -f /var/lib/rpm/__db*

# UPDATE 10/14/2021 - Removed; caused errors in RHEL 8 and unnecessary
# echo '==> Clear out swap and disable until reboot'
# set +e
# swapuuid=$(/sbin/blkid -o value -l -s UUID -t TYPE=swap)
# case "$?" in
# 	2|0) ;;
# 	*) exit 1 ;;
# esac
# set -e
# if [ "x${swapuuid}" != "x" ]; then
#     # Whiteout the swap partition to reduce box size
#     # Swap is disabled till reboot
#     swappart=$(readlink -f /dev/disk/by-uuid/$swapuuid)
#     /sbin/swapoff "${swappart}"
#     dd if=/dev/zero of="${swappart}" bs=1M || echo "dd exit code $? is suppressed"
#     /sbin/mkswap -U "${swapuuid}" "${swappart}"
# fi

# UPDATE 10/14/2021 - Removed; caused errors in RHEL 8 and unnecessary
# echo '==> Zero out empty area to save space in the final image'
# # Zero out the free space to save space in the final image.  Contiguous
# # zeroed space compresses down to nothing.
# dd if=/dev/zero of=/EMPTY bs=1M || echo "dd exit code $? is suppressed"
# rm -f /EMPTY

# Block until the empty file has been removed, otherwise, Packer
# will try to kill the box while the disk is still full and that's bad
sync

echo "==> Disk usage before cleanup"
echo ${DISK_USAGE_BEFORE_CLEANUP}

echo "==> Disk usage after cleanup"
df -h
nmcli con sh