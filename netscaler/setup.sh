# k3d cluster delete netscaler

k3d cluster create netscaler \
  --api-port 6550 -p "8081:80@loadbalancer" \
  --k3s-arg "--disable=traefik@server:*" \
  --wait

helm repo add netscaler https://netscaler.github.io/netscaler-helm-charts/
helm install gateway-controller netscaler/netscaler-kubernetes-gateway-controller -f values.yaml
 
kubectl create secret  generic nslogin --from-literal=username=netscaler --from-literal=password=netscaler