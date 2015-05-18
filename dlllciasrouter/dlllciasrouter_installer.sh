# 必須要設定內部網路
if ! echo `ifconfig` | grep 10.0.0.254  > /dev/null; then
    echo "You have to setup an Internel Network in Zentyal > Network > Interfaces."
    echo "Method: Static"
    echo "Not External (WAN)"
    echo "IP adress: 10.0.0.254"
    echo "Netmask: 255.0.0.0"
    exit
else
    echo "Internal Network is ready."
fi

if ! which pound > /dev/null; then
    sudo apt-get -y --force-yes update
    sudo apt-get -y --force-yes install zentyal-network zentyal-objects zentyal-firewall zentyal-dns zentyal-services zentyal-dhcp pound lighttpd
fi

# 檢查模組的啟用狀態
#echo "Check module enabled...";
DISABLED_MODULES=""
if ! echo `sudo /etc/init.d/zentyal network status` | grep RUNNING > /dev/null; then
    DISABLED_MODULES=$DISABLED_MODULES"Network "
fi
if ! echo `sudo /etc/init.d/zentyal dns status` | grep RUNNING > /dev/null; then
    DISABLED_MODULES=$DISABLED_MODULES"DNS "
fi
if ! echo `sudo /etc/init.d/zentyal dhcp status` | grep RUNNING > /dev/null; then
    DISABLED_MODULES=$DISABLED_MODULES"DHCP "
fi
if ! echo `sudo /etc/init.d/zentyal firewall status` | grep RUNNING > /dev/null; then
    DISABLED_MODULES=$DISABLED_MODULES"Firewall "
fi

if [ "$DISABLED_MODULES" != "" ] ; then
    echo "You have to enable "$DISABLED_MODULES"before you install DLLL-CIAS Router."
    exit
else
    echo "All modules enabled."
fi

exit

cd /tmp
wget https://raw.githubusercontent.com/pulipulichen/zentyal-dlll/master/dlllciasrouter/debs-ppa/zentyal-dlllciasrouter_3.4_all.deb -O zentyal-dlllciasrouter_3.4_all.deb
sudo dpkg -i zentyal-dlllciasrouter_3.4_all.deb
sudo /etc/init.d/zentyal dlllciasrouter restart