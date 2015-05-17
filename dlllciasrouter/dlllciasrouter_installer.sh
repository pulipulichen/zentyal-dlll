sudo apt-get -y --force-yes update
sudo apt-get -y --force-yes install zentyal-network zentyal-objects zentyal-firewall zentyal-dns zentyal-services zentyal-dhcp pound lighttpd
cd /tmp
wget https://raw.githubusercontent.com/pulipulichen/zentyal-dlll/master/dlllciasrouter/debs-ppa/zentyal-dlllciasrouter_3.4_all.deb
sudo dpkg -i zentyal-dlllciasrouter_3.4_all.deb
sudo /etc/init.d/zentyal dlllciasrouter restart