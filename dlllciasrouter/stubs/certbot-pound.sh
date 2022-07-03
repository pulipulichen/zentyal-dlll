#!/bin/sh
for domain in $RENEWED_DOMAINS; do 
  cat "/etc/letsencrypt/live/${domain}/privkey.pem" "/etc/letsencrypt/live/${domain}/fullchain.pem" > "/etc/pound/cert/${domain}.pem"
  /etc/init.d/pound restart
done
