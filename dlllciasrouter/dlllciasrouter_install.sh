# https://github.com/pulipulichen/zentyal-dlll/raw/master/dlllciasrouter/dlllciasrouter_install.sh

# wget http://goo.gl/P3qFIS -O dlllciasrouter_install.sh
# chmod 777 dlllciasrouter_install.sh
# ./dlllciasrouter_install.sh

# wget http://goo.gl/8pj7la -O d.sh;chmod +x d.sh;./d.sh

cd ~
sudo apt-get update
sudo apt-get install -y pound

wget -N https://github.com/pulipulichen/zentyal-dlll/raw/3.0/dlllciasrouter/debs-ppa/zentyal-dlllciasrouter_3.0_all.deb
sudo dpkg -i zentyal-dlllciasrouter_3.0_all.deb