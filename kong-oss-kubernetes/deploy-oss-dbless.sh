#!/bin/bash

# Define colors
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Create KinD cluster
kind create cluster --name kind --config=../kinD-cluster-config/KinD.yaml

# Add kong Helm repository
helm repo add kong https://charts.konghq.com

# Update Repositories
helm repo update

#first clear existing config
kubectl delete namespace kong

# Create Kong Namespace
kubectl create namespace kong

# Create Kong ConfigMap
kubectl create configmap kong-config --from-file=config/kong.yml -n kong

# Install Kong OSS in dbless mode

helm install kong-oss kong/kong -n kong --values values-oss-dbless.yaml

# Test default service
http http://localhost:80/mock

# If you want to deploy using the decK
# deck gateway sync config/kong.yml --kong-addr http://localhost:30001

# If you want to upgrade
# helm upgrade kong-oss kong/kong -n kong --values values-oss-dbless.yaml