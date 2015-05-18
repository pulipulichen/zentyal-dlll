cd ~/zentyal-dlll/dlllciasrouter

echo ""
echo ""
echo "---------------------------------------"
sh h_check.sh
echo "---------------------------------------"
echo ""
echo ""
echo "Check completed. Wait for 3 sec and start to compile...3..."
sleep 1
echo "2..."
sleep 1
echo "1..."
rm -rf debs-ppa/*
zentyal-package
sudo dpkg -i debs-ppa/zentyal-*_all.deb

sudo /etc/init.d/zentyal dlllciasrouter restart