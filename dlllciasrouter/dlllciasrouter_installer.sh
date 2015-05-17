cd /tmp
wget https://raw.githubusercontent.com/pulipulichen/zentyal-dlll/master/dlllciasrouter/debs-ppa/zentyal-dlllciasrouter_3.4_all.deb
sudo dpkg -i zentyal-dlllciasrouter_3.4_all.deb
sudo /etc/init.d/zentyal dlllciasrouter restart