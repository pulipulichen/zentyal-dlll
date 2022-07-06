#!/bin/sh
for domain in $RENEWED_DOMAINS; do 
  if [ -d "/etc/letsencrypt/live/${domain}" ]
  then
    cat "/etc/letsencrypt/live/${domain}/privkey.pem" "/etc/letsencrypt/live/${domain}/fullchain.pem" > "/etc/pound/cert/${domain}.pem"
  fi
done
/etc/init.d/pound restart
