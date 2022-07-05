
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
  TSIG_SECRET: <REDACTED>
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
            nameserver: <ZENTYAL-IP>
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
    - dlll.nccu.edu.tw
    - "*.dlll.nccu.edu.tw"
  issuerRef:
    name: letsencrypt-production
    kind: ClusterIssuer
````