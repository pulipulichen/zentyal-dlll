# Variables

* <SECRET_KEY>: The content of `/etc/bind/Kcertbot.key`.
* <EMAIL>: Your email.
* <ZENTYAL_IP>: Zentyal IP.
* <PRIMARY_DOMAIN_NAME>: For example: `dlll.nccu.edu.tw`.
* <TXT_TEST>: For example: `9.9.9.9`

# Test dns-rfc2136 on localhost

## Add TXT record to DNS

````bash
sudo nsupdate -k /etc/bind/Kcertbot.+165
server 127.0.0.1
update add _acme-challenge.<PRIMARY_DOMAIN_NAME> 86400 TXT <TXT_TEST>
send
quit
````

## Check if the TXT record is added successfully

````bash
dig @127.0.0.1 _acme-challenge.<PRIMARY_DOMAIN_NAME> txt
````

If you see the following message, it means success:

````
;; ANSWER SECTION
_acme-challenge.<PRIMARY_DOMAIN_NAME>. 21600 IN TXT "<TXT_TEST>"
````

# Install Cert-Manager on Kubernetes

Reference:
https://rkevin.dev/blog/automating-wildcard-certificate-issuing-in-k8s/

## Cert Manager

````yaml
apiVersion: v1
kind: Secret
metadata:
  name: zentyal-dns-acme-named-key
  namespace: cert-manager
type: Opaque
stringData:
  TSIG_SECRET: <SECRET_KEY>
````

````yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: zentyal-dns-issuer
spec:
  acme:
    email: <EMAIL>
    
    # Production: 25/week
    #server: https://acme-v02.api.letsencrypt.org/directory
    # Staging: 100/hour
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    # If you want to change staging to production, remember to delete the tls secret file.

    privateKeySecretRef:
      # Secret resource used to store the account's private key.
      name: zentyal-dns-issuer
    solvers:
      - dns01:
          rfc2136:
            nameserver: <ZENTYAL_IP>
            tsigKeyName: certbot.
            tsigAlgorithm: HMACSHA512
            tsigSecretSecretRef:
              name: zentyal-dns-acme-named-key
              key: TSIG_SECRET
````

````yaml
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: zentyal-dns-cert
spec:
  commonName: zentyal-dns-cert
  secretName: zentyal-dns-cert.tls
  dnsNames:
    - "*.<PRIMARY_DOMAIN_NAME>"
    - "*.paas.<PRIMARY_DOMAIN_NAME>"
    - "*.paas-vpn.<PRIMARY_DOMAIN_NAME>"
  issuerRef:
    name: zentyal-dns-issuer
    kind: ClusterIssuer
````

## Ingress
````yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-ingress.<PRIMARY_DOMAIN_NAME>
spec:
  ingressClassName: haproxy
  rules:
    - host: demo.paas.<PRIMARY_DOMAIN_NAME>
      http:
        paths:
          - backend:
              service:
                name: demo-srv
                port:
                  number: 80
            path: /
            pathType: Prefix
  tls:
    - hosts:
        - demo.paas.<PRIMARY_DOMAIN_NAME>
        # don't forget single quote
        - '*.paas.<PRIMARY_DOMAIN_NAME>'
      secretName: zentyal-dns-cert.tls