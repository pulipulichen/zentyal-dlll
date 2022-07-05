#!/bin/sh
for domain in $RENEWED_DOMAINS; do 
  cat "/etc/letsencrypt/live/${domain}/privkey.pem" "/etc/letsencrypt/live/${domain}/fullchain.pem" > "/etc/pound/cert/dlllciasrouter.pem"
done
/etc/init.d/pound restart
