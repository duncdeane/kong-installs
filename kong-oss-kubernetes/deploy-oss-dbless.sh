#!/bin/bash

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

helm install kong-dbless kong/kong -n kong --values values-oss-dbless.yaml --wait --timeout 300s

# Test default service
http http://localhost:80/mock


# Migrate from Kong OSS to Kong Enterprise in DB-less mode

# Step 1: Create the Kong Enterprise license secret
kubectl create secret generic kong-enterprise-license -n kong \
  --from-literal=license="$KONG_LICENSE_DATA"

# Step 2: Upgrade the release with the new values
helm upgrade kong-dbless kong/kong -n kong --values values-ee-dbless.yaml --wait --timeout 300s