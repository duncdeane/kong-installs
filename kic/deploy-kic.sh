#!/bin/bash
 
source .envs

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

 
# Create namespace

kubectl create namespace kong

#create cluster certificate

# Create tLS certs
kubectl create secret tls kong-cluster-cert --cert=./cluster.crt --key=./cluster.key -n kong

# Load License
kubectl create secret generic kong-enterprise-license -n kong \
  --from-literal=license="$KONG_LICENSE_DATA"

# Create Manager Config
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


# Add Helm Repo
helm repo add kong https://charts.konghq.com
helm repo update


kubectl create secret generic kong-enterprise-superuser-password --from-literal=password=password -n kong

helm install -f values.yaml kong kong/ingress -n kong \
--set manager.ingress.hostname=manager.kong.lan \
--set admin.ingress.hostname=admin.kong.lan



GW_WAIT_POD=$(kubectl get pods --selector=app=kong-gateway -n kong -o jsonpath='{.items[*].metadata.name}')
CONTROLLER_WAIT_POD=$(kubectl get pods --selector=app=kong-controller -n kong -o jsonpath='{.items[*].metadata.name}')
echo "Kong Gateway and Controller pods created. Waiting for them to come online..."
kubectl wait --for=condition=Ready --timeout=300s pod $GW_WAIT_POD -n kong
kubectl wait --for=condition=Ready --timeout=300s pod $CONTROLLER_WAIT_POD -n kong


echo ""
echo "The system is ready"