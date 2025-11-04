# Deploy Kong OSS (DB-less)

This README is a simple, step-by-step guide to deploy Kong OSS in DB-less mode using the Helm chart and the helper script `deploy-oss-dbless.sh` in this directory.

Run the commands from the `kong-oss-kubernetes` directory.

## Prerequisites

- kind (Kubernetes in Docker)
- kubectl (configured to your cluster)
- helm v3
- httpie or curl (for basic HTTP tests)
- (optional) deck if you manage config with decK

## Files referenced

- `deploy-oss-dbless.sh` — convenience script that automates the steps in this README
- `values-oss-dbless.yaml` — Helm values for an OSS DB-less Kong installation
- `values-oss-to-ee-dbless.yaml` — example values file for upgrading to Kong Enterprise (DB-less)
- `config/kong.yml` — your DB-less Kong configuration file

## Steps

1. Create a KinD cluster (optional)

```bash
kind create cluster --name kind --config=../kinD-cluster-config/KinD.yaml
```

2. Add and update the Kong Helm repo

```bash
helm repo add kong https://charts.konghq.com || true
helm repo update
```

3. (Re)create the `kong` namespace

> WARNING: deleting the namespace will remove all Kong resources and data in that namespace.

```bash
# (optional) delete existing namespace
kubectl delete namespace kong || true

# create namespace
kubectl create namespace kong
```

4. Create the DB-less ConfigMap (contains your `kong.yml`)

```bash
kubectl create configmap kong-config --from-file=config/kong.yml -n kong --dry-run=client -o yaml | kubectl apply -f -
```

5. Install Kong OSS (DB-less)

```bash
helm install kong-oss kong/kong -n kong --values values-oss-dbless.yaml --wait --timeout 300s
```

6. Smoke test the default service

```bash
# using httpie
http http://localhost:80/mock

# or using curl
curl -i http://localhost:80/mock
```

## Optional: manage Kong config with decK

If you use decK to manage Kong configuration, sync local config to the gateway after deployment:

```bash
# deck gateway sync config/kong.yml --kong-addr http://localhost:30001
```

## Optional: Upgrade to Kong Enterprise (DB-less)

1. Edit `values-oss-to-ee-dbless.yaml` so it enables enterprise and points to a license secret:

```yaml
enterprise:
    enabled: true
    license_secret: kong-enterprise-license
```


- Create the Enterprise license secret (two options):

```bash
# from environment variable KONG_LICENSE_DATA
kubectl create secret generic kong-enterprise-license -n kong \
    --from-literal=license="$KONG_LICENSE_DATA"

# or from a local file
# kubectl create secret generic kong-enterprise-license -n kong --from-file=license=./kong-license.json
```

- Run the Helm upgrade

```bash
helm upgrade kong-oss kong/kong -n kong --values values-oss-to-ee-dbless.yaml --wait --timeout 300s
```

## Verification and troubleshooting

- Check pods and rollout status:

```bash
kubectl -n kong get pods
kubectl -n kong rollout status deployment kong-kong --timeout=300s || true
```

- Inspect a pod to confirm image and env vars (license usage):

```bash
kubectl -n kong describe pod <pod-name>
```

- If Helm errors about incompatible values, pin the chart version with `--version` to the same chart used previously.

## Notes

- Keep DB-less mode with `env.database: "off"` and ensure `dblessConfig.configMap` points to `kong-config`.
- Be careful deleting the `kong` namespace — it removes all Kong resources and data in that namespace.

---

Generated from `deploy-oss-dbless.sh` in this repository.
