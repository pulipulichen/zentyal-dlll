cd ~/dlll_cias_router
sh h_check.sh
echo "Check completed. Wait for 3 sec and start to compile...3..."
sleep 1
echo "2..."
sleep 1
echo "1..."
zentyal-package
sudo dpkg -i debs-ppa/zentyal-dlll_cias_router_3.0_all.deb
