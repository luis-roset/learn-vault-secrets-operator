# Enable PKI
vault secrets enable pki
vault secrets tune -max-lease-ttl=8760h pki
vault write pki/root/generate/internal \
    common_name="example.com" \
    ttl=8760h
    
vault write pki/config/urls \
    issuing_certificates="http://localhost:8200/v1/pki/ca" \
    crl_distribution_points="http://localhost:8200/v1/pki/crl"

# Create Role
vault write pki/roles/example-dot-com \
    allowed_domains="example.com" \
    allow_subdomains=true \
    max_ttl="72h"
    
# Create Policy
echo '
path "pki/issue/example-dot-com" {
  capabilities = ["create", "update"]
}
' > pki-policy.hcl
vault policy write pki-policy pki-policy.hcl

# Enable Kubernetes Auth
vault auth enable kubernetes

vault write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    token_reviewer_jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token

# Create Kubernetes Role
vault write auth/kubernetes/role/example-role \
    bound_service_account_names=example-sa \
    bound_service_account_namespaces=default \
    policies=example-dot-com-policy \
    ttl=24h
    
# Request Certificate
vault write pki/issue/example-dot-com \
    common_name="mobile.example.com" \
    ttl="24h"