#! /bin/bash
## Kubernetes Installation

### Create Namespaces

kubectl create namespace kong
kubectl create namespace kong-dp


### Create Control Plane Secrets

kubectl -n kong create secret tls kong-cluster-cert --cert=./cluster.crt --key=./cluster.key
kubectl -n kong create secret generic kong-enterprise-superuser-password --from-literal=password=password

### Load Kong License File

kubectl create secret generic kong-enterprise-license -n kong \
  --from-literal=license="$KONG_LICENSE_DATA"

### Create Kong Manager Session Configuration Secret

cat << EOF > admin_gui_session_conf
{
    "cookie_name":"admin_session",
    "cookie_samesite":"off",
    "secret":"kong",
    "cookie_secure":true,
    "storage":"kong"
}
EOF
kubectl create secret generic kong-session-config -n kong --from-file=admin_gui_session_conf

### Create Data Plane Secrets

kubectl create secret tls kong-cluster-cert --cert=./cluster.crt --key=./cluster.key -n kong-dp
kubectl create secret generic kong-enterprise-license -n kong-dp \
  --from-literal=license="$KONG_LICENSE_DATA"


### Add Helm Repository

helm repo add kong https://charts.konghq.com
helm repo update

### Configure Environment Variables

export KONG_ADMIN_GUI_URL="http://localhost:30002"
export KONG_ADMIN_GUI_API_URL="http://localhost:30001"
export KONG_PROXY_URL="http://localhost:30000"

### Deploy Control Plane

helm install -f cp-values.yaml kong kong/kong -n kong --version 2.16.5

# helm install -f ./kubernetes/cp-values.yaml kong kong/kong -n kong

### Deploy Data Plane

helm install -f dp-values.yaml kong kong/kong -n kong-dp --version 2.16.5

clear

### Wait for Control Plane to be Ready
echo "Waiting for Kong Control Plane to be ready. This can take up to 1 minute..."
kubectl -n kong rollout status deployment kong-kong --timeout=300s

if [ $? -ne 0 ]; then
  echo "Control Plane failed to become ready in time."
  exit 1
fi

echo "Control Plane is active!"
 
echo "Deploying Sample Gateway Service..."

sleep 2

deck gateway sync kubernetes/kong.yaml --kong-addr http://localhost:30001
