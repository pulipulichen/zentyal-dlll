#!/bin/sh
for domain in $RENEWED_DOMAINS; do 
  if [ -d "/etc/letsencrypt/live/${domain}" ]
  then
    cat "/etc/letsencrypt/live/${domain}/privkey.pem" "/etc/letsencrypt/live/${domain}/fullchain.pem" > "/etc/pound/cert/${domain}.pem"
  fi
done

rm -rf /etc/lighttpd/lighttpd.conf
cp /etc/lighttpd/lighttpd.conf.default /etc/lighttpd/lighttpd.conf
/etc/init.d/lighttpd restart

/etc/init.d/pound restart
