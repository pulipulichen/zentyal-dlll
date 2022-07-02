sudo rm -r /var/log/zentyal/zentyal.log
./git_update_compile.sh
echo "======================"
echo "zentyal.log"
echo "======================"
cat /var/log/zentyal/zentyal.log