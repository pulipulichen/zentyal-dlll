# 啟用Sudo
sudo ls >> /dev/null

# 必須要設定內部網路
if ! echo `ifconfig` | grep 10.0.0.254  > /dev/null; then
    echo "You have to setup an Internel Network in Zentyal > Network > Interfaces."
    echo "Method: Static"
    echo "Not External (WAN)"
    echo "IP adress: 10.0.0.254"
    echo "Netmask: 255.0.0.0"
    exit
fi
echo "Internal Network is ready."

# 加入MFS所需要的設定
if ! echo `cat /etc/hosts` | grep mfsmaster  > /dev/null; then
    sudo -- sh -c "echo '10.0.0.254      mfsmaster' >> /etc/hosts"
fi
echo "Hostname \"mfsmaster\" is ready."

# moosefs的資料庫
if ! [ -f /etc/apt/sources.list.d/moosefs.list ] ; then
    wget http://ppa.moosefs.com/moosefs.key
    sudo apt-key add moosefs.key
    rm moosefs.key
    echo "deb http://ppa.moosefs.com/moosefs-3/apt/ubuntu/trusty trusty main" | sudo tee /etc/apt/sources.list.d/moosefs.list
    sudo apt-get update -y
fi
echo "MooseFS apt repository is ready."

# 要加入mfs
if ! id mfs > /dev/null 2>&1 ; then
    sudo useradd mfs
fi
echo "User mfs added."

# 建立 mfs 所需要的目錄
if ! [ -d /mnt/mfs ] ; then
    sudo mkdir -p /mnt/mfs
fi

if ! [ -d /opt/mfschunkservers/localhost/mfs ] ; then
    sudo mkdir -p /opt/mfschunkservers/localhost/mfs
    sudo chown -R mfs:mfs /opt/mfschunkservers/localhost
fi
sudo chown -R mfs:mfs /var/lib/mfs
echo "MooseFS directories are ready."
 
# 設定安裝的東西
if ! ( [ `which pound` ] && [ `which lighttpd` ] && [ -f /etc/init.d/moosefs-master ] && [ -f /etc/init.d/nfs-kernel-server ] ) ; then
    sudo apt-get -y --force-yes update
    sudo apt-get -y --force-yes install zentyal-network zentyal-objects \
zentyal-firewall zentyal-dns zentyal-services zentyal-dhcp \
pound lighttpd \
moosefs-master moosefs-cli moosefs-chunkserver  moosefs-metalogger moosefs-client moosefs-cgiserv \
nfs-kernel-server nfs-common \
vim locate libdistro-info-perl  build-essential gcc zbuildtools fakeroot git pound
    sudo updatedb
    mkdir -p ~/zentyal-dlll
fi
echo "All modules are installed."

# 檢查模組的啟用狀態
#echo "Check module enabled...";
DISABLED_MODULES=""
GREP_STR="\[ RUNNING \]"
if ! echo `sudo /etc/init.d/zentyal network status` | grep "$GREP_STR" > /dev/null; then
    DISABLED_MODULES=$DISABLED_MODULES"Network "
fi
if ! echo `sudo /etc/init.d/zentyal dns status` | grep "$GREP_STR" > /dev/null; then
    DISABLED_MODULES=$DISABLED_MODULES"DNS "
fi
if ! echo `sudo /etc/init.d/zentyal dhcp status` | grep "$GREP_STR" > /dev/null; then
    DISABLED_MODULES=$DISABLED_MODULES"DHCP "
fi
if ! echo `sudo /etc/init.d/zentyal firewall status` | grep "$GREP_STR" > /dev/null; then
    DISABLED_MODULES=$DISABLED_MODULES"Firewall "
fi
if ! echo `sudo /etc/init.d/zentyal logs status` | grep "$GREP_STR" > /dev/null; then
    DISABLED_MODULES=$DISABLED_MODULES"Logs "
fi

if [ "$DISABLED_MODULES" != "" ] ; then
    echo "You have to enable "$DISABLED_MODULES"in Zentyal before you install DLLL-CIAS Router."
    exit
else
    echo "All modules are enabled."
fi

# 如果要測試，做到這邊即可
if [ -f ~/zentyal-dlll/dlllciasrouter/debs-ppa/zentyal-dlllciasrouter_3.4_all.deb ] ; then
    echo "Test complete"
    exit
fi

# -----------------------------------
# Setup GIT
# -----------------------------------

# -----------------------------------

cd /tmp
wget https://raw.githubusercontent.com/pulipulichen/zentyal-dlll/master/dlllciasrouter/debs-ppa/zentyal-dlllciasrouter_3.4_all.deb -O zentyal-dlllciasrouter_3.4_all.deb
#wget http://192.168.11.50/zentyal-dlll/dlllciasrouter/debs-ppa/zentyal-dlllciasrouter_3.4_all.deb -O zentyal-dlllciasrouter_3.4_all.deb
sudo dpkg -i zentyal-dlllciasrouter_3.4_all.deb
sudo /etc/init.d/zentyal dlllciasrouter restart

if ! echo `sudo /etc/init.d/zentyal dlllciasrouter status` | grep "$GREP_STR" > /dev/null; then
    echo "Please enable DLLL-CIAS Router module in Zentyal."
fi