# 啟用Sudo
sudo ls >> /dev/null

# 必須要設定內部網路
if ! echo `ifconfig` | grep 10.0.0.254  > /dev/null; then
    echo "[DCR] You have to setup an Internel Network in Zentyal > Network > Interfaces."
    echo "[DCR] Method: Static"
    echo "[DCR] Not External (WAN)"
    echo "[DCR] IP adress: 10.0.0.254"
    echo "[DCR] Netmask: 255.0.0.0"
    exit
fi
echo "[DCR] Internal Network is ready."

# 加入MFS所需要的設定
if ! echo `cat /etc/hosts` | grep mfsmaster  > /dev/null; then
    sudo -- sh -c "echo '10.0.0.254      mfsmaster' >> /etc/hosts"
fi
echo "[DCR] Hostname \"mfsmaster\" is ready."

# moosefs的資料庫
if ! [ -f /etc/apt/sources.list.d/moosefs.list ] ; then
    #wget -O - http://ppa.moosefs.com/apt/moosefs.key | sudo apt-key add -
    wget http://ppa.moosefs.com/moosefs.key
    sudo apt-key add moosefs.key
    rm moosefs.key
    echo "deb http://ppa.moosefs.com/moosefs-3/apt/ubuntu/trusty trusty main" | sudo tee /etc/apt/sources.list.d/moosefs.list
    sudo apt-get update -y
fi
echo "[DCR] MooseFS apt repository is ready."

# 要加入mfs
if ! id mfs > /dev/null 2>&1 ; then
    sudo useradd mfs
fi
echo "[DCR] User mfs added."

# 建立 mfs 所需要的目錄
if ! [ -d /mnt/mfs ] ; then
    sudo mkdir -p /mnt/mfs
fi

if ! [ -d /opt/mfschunkservers/localhost/mfs ] ; then
    sudo mkdir -p /opt/mfschunkservers/localhost/mfs
    sudo chown -R mfs:mfs /opt/mfschunkservers/localhost
fi
sudo mkdir -p /var/lib/mfs
sudo chown -R mfs:mfs /var/lib/mfs
echo "[DCR] MooseFS directories are ready."
 
# 設定安裝的東西
sudo mkdir -p ~/zentyal-dlll
if ! ( [ `which pound` ] && [ `which lighttpd` ] && [ -f /etc/init.d/moosefs-master ] && [ -f /etc/init.d/nfs-kernel-server ] ) ; then
    sudo apt-get -y update
    sudo apt-get -y install zentyal-network zentyal-objects \
zentyal-firewall zentyal-dns zentyal-services zentyal-dhcp \
pound lighttpd \
moosefs-master moosefs-cli moosefs-chunkserver moosefs-metalogger moosefs-client moosefs-cgiserv \
nfs-kernel-server nfs-common vim locate
    sudo apt-get -y install libdistro-info-perl  build-essential gcc zbuildtools fakeroot git pound vim
    sudo updatedb
fi
echo "All modules are installed."

mkdir -p ~/zentyal-dlll