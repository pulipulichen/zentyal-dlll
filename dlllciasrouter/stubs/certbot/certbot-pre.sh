#!/bin/sh
/etc/init.d/pound stop

rm -rf /etc/lighttpd/lighttpd.conf
cp /etc/lighttpd/lighttpd.conf.certbot /etc/lighttpd/lighttpd.conf
/etc/init.d/lighttpd restart
