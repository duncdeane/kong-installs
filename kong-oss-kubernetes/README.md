# Kong OSS Deployment (DBLESS)

This guide describes how to deploy **Kong Gateway OSS** in **DB-less mode** on a KinD cluster, and then migrate it to **Kong Enterprise**.

---

## Prerequisites

Before you begin, make sure you have the following installed:

* [KinD](https://kind.sigs.k8s.io/)
* [kubectl](https://kubernetes.io/docs/tasks/tools/)
* [Helm](https://helm.sh/)
* [HTTPie](https://httpie.io/) (for testing)
* A valid **Kong Enterprise license** stored in the environment variable:

  ```bash
  export KONG_LICENSE_DATA='<your_license_data>'
  ```

---

## 1. Create the KinD Cluster

```bash
kind create cluster --name kind --config=../kinD-cluster-config/KinD.yaml
```

---

## 2. Add and Update Helm Repositories

```bash
helm repo add kong https://charts.konghq.com
helm repo update
```

---

## 3. Prepare the Namespace and Configuration

First, ensure any existing Kong namespace is removed, then recreate it:

```bash
kubectl delete namespace kong
kubectl create namespace kong
```

Create a ConfigMap for Kong’s configuration file:

```bash
kubectl create configmap kong-config --from-file=config/kong.yml -n kong
```

---

## 4. Install Kong OSS (DB-less Mode)

Install Kong OSS using Helm:

```bash
helm install kong-dbless kong/kong -n kong --values values-oss-dbless.yaml --wait --timeout 300s
```

---

## 5. Test the Default Service

Verify that Kong is running and accessible:

```bash
http http://localhost:80/mock
```

---

## 6. Migrate to Kong Enterprise (DB-less Mode)

### Step 1: Create the Enterprise License Secret

```bash
kubectl create secret generic kong-enterprise-license -n kong \
  --from-literal=license="$KONG_LICENSE_DATA"
```

### Step 2: Upgrade the Deployment

Upgrade the existing OSS release to Enterprise:

```bash
helm upgrade kong-dbless kong/kong -n kong --values values-ee-dbless.yaml --wait --timeout 300s
```

---

## Notes

* The configuration file (`config/kong.yml`) and Helm values files (`values-oss-dbless.yaml`, `values-ee-dbless.yaml`) must be present before running the commands.
* Adjust timeouts and resource limits as needed for your local environment.
* Ensure that the license data is valid and correctly formatted JSON.

---

## Cleanup

To delete the cluster and all associated resources:

```bash
kind delete cluster --name kind
```
