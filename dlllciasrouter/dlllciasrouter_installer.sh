if [ "$EUID" -eq 0 ]
  then echo "Please don't run as root"
  exit
fi

# 啟用Sudo
sudo ls >> /dev/null

chmod +x ~/d.sh

if [ -f ~/git-init.sh ] ; then
    # 已經下載的狀態下，我們只做程式碼的更新
    clear
    cd ~/zentyal-dlll/dlllciasrouter/
    bash ~/zentyal-dlll/dlllciasrouter/git_update_compile_log.sh
    echo "===================================";
    echo "DLLL-CIAS Router is updated"
    echo "===================================";
    exit
fi

# -------------------------------

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
 
# ----------------------------

# 設定安裝的東西
if ! ( [ `which pound` ] && [ `which lighttpd` ] && [ -f /etc/init.d/moosefs-master ] && [ -f /etc/init.d/nfs-kernel-server ] ) ; then
    sudo apt-get -y --force-yes update

PACKAGE="zentyal-network zentyal-objects \
zentyal-firewall zentyal-dns zentyal-services zentyal-dhcp \
pound snapd \
lighttpd \
moosefs-master moosefs-cli moosefs-chunkserver  moosefs-metalogger moosefs-client moosefs-cgiserv \
nfs-kernel-server nfs-common \
vim locate libdistro-info-perl  build-essential gcc zbuildtools fakeroot git pound \
mutt sendmail sendmail-bin mailutils \
openjdk-7-jre icedtea-7-plugin \
xrdp xfce4 xfce4-goodies tightvncserver"

    sudo apt-get -y --force-yes install $PACKAGE

    sudo apt-get -y --force-yes install $PACKAGE

    #sudo updatedb

    # lighttpd enable php
    #sudo lighttpd-enable-mod fastcgi fastcgi-php
    #sudo service lighttpd force-reload

    # install certbot with snap
    sudo snap install core
    sudo snap install --classic certbot
    sudo snap set certbot trust-plugin-with-root=ok
    sudo snap install certbot-dns-rfc2136
    sudo ln -s /snap/bin/certbot /usr/bin/certbot

    # Install chinese fonts
    sudo apt-get install fonts-wqy-zenhei -y
fi
echo "All modules are installed."

# -----------------------------------
# 檢查模組的啟用狀態
# -----------------------------------

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
# 檔案控制
# -----------------------------------

# 20170731 系統檔案功能需要
sudo mkdir -p /usr/share/zentyal/www/dlllciasrouter/files

# 20170903 增加排程備份的任務
LIST=`sudo crontab -l`
echo "$LIST"
SOURCE="/root/dlllciasrouter/backup-zentyal.sh"
if echo "$LIST" | grep -q "$SOURCE"; then
  echo "The backup job had been added.";
else
  sudo crontab -l | { cat; echo "0  6  * * 7   $SOURCE"; } | sudo crontab -
fi

# 20170917 增加排程備份的任務：重開機之後執行
SOURCE="/root/dlllciasrouter/startup-message.sh"
if echo "$LIST" | grep -q "$SOURCE"; then
  echo "The startup message job had been added.";
else
  sudo crontab -l | { cat; echo "@reboot $SOURCE"; } | sudo crontab -
fi

# 20220918 增加certbot
SOURCE="/root/dlllciasrouter/certbot-renew.sh"
if echo "$LIST" | grep -q "$SOURCE"; then
  echo "The Certbot renew job had been added.";
else
  sudo crontab -l | { cat; echo "0  6  1,15 * 7   $SOURCE"; } | sudo crontab -
fi

# 20181109 增加firefox的啟動指令
echo 'pkill -f firefox;/usr/share/zenbuntu-desktop/firefox-launcher' >> ~/Desktop/start-Firefox.sh
chmod +x ~/Desktop/start-Firefox.sh

# -----------------------------------
# Wildcard DNS
# 20220703-1551 
#echo "Wildcard DNS"

cd /etc/bind
sudo dnssec-keygen -a HMAC-SHA512 -b 512 -n HOST certbot.
sudo bash -c 'grep "^Key: " /etc/bind/Kcertbot.+165+*.private | cut -d" " -f 2 > /etc/bind/Kcertbot.key'
sudo bash -c 'cp /etc/bind/Kcertbot.+165+*.private /etc/bind/Kcertbot.+165.private'
sudo bash -c 'cp /etc/bind/Kcertbot.+165+*.key /etc/bind/Kcertbot.+165.key'

sudo mkdir -p /etc/pound/cert/
sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy/
sudo mkdir -p /var/lib/bind/
sudo touch /etc/bind/named.conf.certbot

# -----------------------------------
# Setup GIT
# -----------------------------------

mkdir -p ~/zentyal-dlll
cd ~
wget https://pulipulichen.github.io/zentyal-dlll/dlllciasrouter/git-init.sh -O git-init.sh
bash git-init.sh

# -----------------------------------
# Wildcard DNS
# 20220703-1551 

sudo cp -f ~/zentyal-dlll/dlllciasrouter/stubs/dns/db.mas /usr/share/zentyal/stubs/dns/db.mas
sudo cp -f ~/zentyal-dlll/dlllciasrouter/stubs/dns/named.conf.mas /usr/share/zentyal/stubs/dns/named.conf.mas
sudo cp -f ~/zentyal-dlll/dlllciasrouter/stubs/certbot/certbot-deploy-wildcard.sh /etc/letsencrypt/renewal-hooks/deploy/
sudo cp -f ~/zentyal-dlll/dlllciasrouter/stubs/certbot/certbot-deploy.sh /etc/letsencrypt/renewal-hooks/deploy/
sudo cp -f ~/zentyal-dlll/dlllciasrouter/stubs/certbot/certbot-pre.sh /etc/letsencrypt/renewal-hooks/pre/
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/*.sh
sudo mkdir -p /etc/letsencrypt/renewal-hooks/pre/
sudo chmod +x /etc/letsencrypt/renewal-hooks/pre/*.sh
sudo touch -p /etc/bind/Kcertbot.key

sudo cp -f ~/zentyal-dlll/dlllciasrouter/stubs/lighttpd/* /etc/lighttpd/

# -----------------------------------

bash ~/zentyal-dlll/dlllciasrouter/compile.sh

sudo /etc/init.d/zentyal dlllciasrouter restart

if ! echo `sudo /etc/init.d/zentyal dlllciasrouter status` | grep "$GREP_STR" > /dev/null; then
    echo "Please enable DLLL-CIAS Router module in Zentyal."
fi

# 儲存設定
chmod +x ~/zentyal-dlll/dlllciasrouter/www/dlllciasrouter/local_scripts/SaveAllModules.pm
sudo ~/zentyal-dlll/dlllciasrouter/www/dlllciasrouter/local_scripts/SaveAllModules.pm

# 20181109 增加vncserver自動啟動的功能
if ! [ -f /etc/init.d/vnc ] ; then
    sudo cp -f ~/zentyal-dlll/dlllciasrouter/vnc /etc/init.d/
    sudo chmod +x /etc/init.d/vnc
    sudo sed -i -e "s/ZENTYAL_USER/$USER/" /etc/init.d/vnc
fi

# ----------------------------------------------

# 20181109 增加vncserver啟動任務
LIST=`sudo crontab -l`
SOURCE="service vnc start"
if echo "$LIST" | grep -q "$SOURCE"; then
  echo "The vncserver startup job had been added.";
else
  sudo crontab -l | { cat; echo "@reboot $SOURCE"; } | sudo crontab -
fi

# ----------------------

# 20181109 設定locate的索引，一定要擺到最後執行
sudo updatedb

sudo /etc/init.d/zentyal dlllciasrouter restart

# ----------------------
# 需要詢問的位置

# 20180303 增加遠端桌面連線的功能
vncserver
# 這裡要設定vncserver帳號密碼
sudo /etc/init.d/xrdp restart

echo "===================================";
echo "DLLL-CIAS Router is ready"
echo "===================================";

# 20181109 完成時再來重新開機
sudo reboot