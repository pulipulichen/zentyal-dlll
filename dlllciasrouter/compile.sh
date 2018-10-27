sudo ls >> /dev/null

if [ -d "~/zentyal-dlll/dlllciasrouter" ]; then
  cd ~/zentyal-dlll/dlllciasrouter
fi

if [ -d "zentyal-dlll/dlllciasrouter" ]; then
  cd zentyal-dlll/dlllciasrouter
fi

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
echo ""

rm -rf debs-ppa/*
zentyal-package
sudo dpkg -i debs-ppa/zentyal-*_all.deb

sudo /etc/init.d/zentyal dlllciasrouter restart

if ! echo `sudo /etc/init.d/zentyal dlllciasrouter status` | grep "$GREP_STR" > /dev/null; then
    echo "Please enable DLLL-CIAS Router module in Zentyal."
else
    sudo ~/zentyal-dlll/dlllciasrouter/www/dlllciasrouter/local_scripts/SaveAllModules.pm
fi

tail /var/log/zentyal/zentyal.log