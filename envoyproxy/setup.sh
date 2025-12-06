k3d cluster delete envoyproxy

k3d cluster create envoyproxy \
  --api-port 6550 -p "8081:80@loadbalancer" \
  --k3s-arg "--disable=traefik@server:*" \
  --wait
  # --k3s-arg "--cluster-cidr=10.118.0.0/17@server:*" \
  # --k3s-arg "--service-cidr=10.118.128.0/17@server:*" \
  # --k3s-arg "--disable=servicelb@server:*" \

helm template eg oci://docker.io/envoyproxy/gateway-crds-helm \
  --version v1.6.0 \
  --set crds.gatewayAPI.enabled=true \
  --set crds.gatewayAPI.channel=standard \
  --set crds.envoyGateway.enabled=true \
  | kubectl apply --server-side -f -

helm install eg oci://docker.io/envoyproxy/gateway-helm --version v1.6.0 -n envoy-gateway-system --create-namespace \
  --set config.envoyGateway.extensionApis.enableBackend=true \
  --skip-crds


kubectl wait --timeout=5m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available

# kubectl apply -f https://github.com/envoyproxy/gateway/releases/download/v1.6.0/quickstart.yaml -n default
