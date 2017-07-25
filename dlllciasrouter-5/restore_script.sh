cd ~/zentyal-dlll/dlllciasrouter/
sudo sh ./ntpupdate.sh
sudo rm /var/log/zentyal/zentyal.log
sudo touch /var/log/zentyal/zentyal.log
sudo chown ebox:ebox /var/log/zentyal/zentyal.log