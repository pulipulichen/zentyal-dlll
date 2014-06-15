ps aux | grep /usr/share/zent | awk '{print $2}' | xargs kill -9
/etc/init.d/zentyal start