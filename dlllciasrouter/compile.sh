cd ~/zentyal-dlll/dlllciasrouter
sh h_check.sh
echo "Check completed. Wait for 3 sec and start to compile...3..."
sleep 1
echo "2..."
sleep 1
echo "1..."
rm -rf debs-ppa/*
zentyal-package
sudo dpkg -i debs-ppa/zentyal-*_all.deb
