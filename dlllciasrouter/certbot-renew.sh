/etc/init.d/pound stop
/etc/init.d/lighttpd stop

rm /etc/lighttpd/lighttpd.conf 
cp /etc/lighttpd/lighttpd.conf.certbot /etc/lighttpd/lighttpd.conf
/etc/init.d/lighttpd start

certbot renew

/etc/init.d/lighttpd stop
rm /etc/lighttpd/lighttpd.conf 
cp /etc/lighttpd/lighttpd.conf.default /etc/lighttpd/lighttpd.conf

/etc/init.d/lighttpd start
/etc/init.d/pound start