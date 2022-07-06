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

````yaml
apiVersion: v1
kind: Secret
metadata:
  name: acme-named-key
  namespace: https-cert
type: Opaque
stringData:
  TSIG_SECRET: <SECRET_KEY>
````

````yaml
apiVersion: cert-manager.io/v1alpha3
kind: ClusterIssuer
metadata:
  name: letsencrypt-production
spec:
  acme:
    email: <EMAIL>
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      # Secret resource used to store the account's private key.
      name: letsencrypt-production
    solvers:
      - http01:
          ingress: {}
      - dns01:
          rfc2136:
            nameserver: <ZENTYAL_IP>
            tsigKeyName: cert-manager
            tsigAlgorithm: HMACSHA256
            tsigSecretSecretRef:
              name: acme-named-key
              key: TSIG_SECRET
````

````yaml
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: primary-cert
  namespace: https-cert
spec:
  commonName: rkevin.dev
  secretName: primary-cert-secret
  dnsNames:
    - <PRIMARY_DOMAIN_NAME>
    - "*.<PRIMARY_DOMAIN_NAME>"
    - "paas.<PRIMARY_DOMAIN_NAME>"
    - "*.paas.<PRIMARY_DOMAIN_NAME>"
    - "paas-vpn.<PRIMARY_DOMAIN_NAME>"
    - "*.paas-vpn.<PRIMARY_DOMAIN_NAME>"
  issuerRef:
    name: letsencrypt-production
    kind: ClusterIssuer
````