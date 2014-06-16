# https://github.com/pulipulichen/zentyal-dlll/raw/master/dlllciasrouter/dlllciasrouter_install.sh
# http://goo.gl/P3qFIS

cd ~
sudo apt-get update
sudo apt-get install -y pound

wget -N https://github.com/pulipulichen/zentyal-dlll/raw/master/dlllciasrouter/debs-ppa/zentyal-dlllciasrouter_3.0_all.deb
sudo dpkg -i zentyal-dlllciasrouter_3.0_all.deb