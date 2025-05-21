# Auto-DevOps Project

This repository demonstrates a fully-GitOps workflow for deploying both infrastructure and a sample application on Kubernetes using:

- **Argo CD** (GitOps controller)  
- **Helm** (package manager)  
- **Sealed Secrets** (encrypted secrets in Git)  

---

## Prerequisites

- A Kubernetes cluster (v1.20+) with **LoadBalancer** support  
- `kubectl` configured for your cluster  
- [Helm 3](https://helm.sh/)  
- [Argo CD CLI](https://argo-cd.readthedocs.io/en/stable/cli_installation/)  
- [kubeseal](https://github.com/bitnami-labs/sealed-secrets#client)  

---

## Repository Layout

```
.
├── Makefile
├── app/                            ← your Helm chart
│   ├── Chart.yaml
│   ├── values.yaml                ← non-sensitive defaults
│   ├── values.enc.yaml            ← SealedSecret for passwords
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── ingress.yaml
└── manifests/                      ← Argo CD “Application-of-Applications”
    ├── bootstrap.yaml             ← creates infra- and app-Applications
    ├── infra/                     ← all infra Applications
    │   ├── ingress-controller.yaml
    │   ├── cert-manager.yaml
    │   ├── prometheus.yaml
    │   ├── grafana.yaml
    │   ├── mysql.yaml
    │   └── sealed-secrets.yaml
    └── app/                       ← Application for your sample app
        └── sample-app.yaml
```

---

## Workflow

1. **Install Argo CD**  
   ```bash
   make install-argocd
   ```
2. **Wait until Argo CD is healthy**  
   ```bash
   make wait-argocd
   ```
3. **Register your Git repo**  
   ```bash
   export GIT_REPO=git@github.com:<your-org>/<your-repo>.git
   make login-repo
   ```
4. **Bootstrap infrastructure & app**  
   ```bash
   make bootstrap-infra
   ```
   This applies `manifests/bootstrap.yaml`, which in turn tells Argo CD to create:
   - `infra-bootstrap` → installs **Ingress**, **Cert-Manager**, **Prometheus**, **Grafana**, **MySQL**, **SealedSecrets**  
   - `app`            → installs your **Sample App** from the local Helm chart  

   Each child Application in `manifests/infra/` and `manifests/app/` is auto-synced (prune + self-heal).

5. **Access your services**  
   - **Ingress NGINX** → LoadBalancer IP on port 80/443  
   - **Argo CD UI** → `https://<ARGOCD_SERVER>`  
   - **Grafana UI** → LoadBalancer IP on port 3000 (default admin/admin)  
   - **Prometheus UI** → LoadBalancer IP on port 9090  

---

## Sealing `values.yaml` with Sealed Secrets

To keep database passwords out of plaintext Git history:

1. **Fetch the public cert** from your cluster (one-time):  
   ```bash
   kubeseal --fetch-cert      --controller-namespace sealed-secrets      --controller-name sealed-secrets-controller      > pub-cert.pem
   ```
2. **Create a dry-run Secret** from your `values.yaml`:  
   ```bash
   kubectl create secret generic mysql-values      --from-file=values.yaml      --dry-run=client      -o yaml > mysql-secret.yaml
   ```
3. **Seal** it into `app/values.enc.yaml`:  
   ```bash
   kubeseal      --cert pub-cert.pem      --format yaml < mysql-secret.yaml      > app/values.enc.yaml
   ```
4. **Commit** `app/values.enc.yaml` (and **never** commit the unsealed Secret!).

When Argo CD applies your SealedSecret, the Sealed-Secrets controller will decrypt it into a regular `Secret`, and Helm will pick up the passwords from there.

---

## Makefile Targets

| Target            | Description                                           |
|-------------------|-------------------------------------------------------|
| `install-argocd`  | Add Helm repo & install Argo CD into `argocd/` ns     |
| `wait-argocd`     | Block until `argocd-server` deployment is available   |
| `login-repo`      | Log in to Argo CD CLI & register your Git repository  |
| `bootstrap-infra` | Apply `manifests/bootstrap.yaml` to kick off all Apps |
| `clean`           | Delete bootstrap Apps & uninstall Argo CD             |

---

## Further Reading

- [Argo CD GitOps Principles](https://argo-cd.readthedocs.io/)  
- [Helm Charts Best Practices](https://helm.sh/docs/chart_best_practices/)  
- [Sealed Secrets Documentation](https://github.com/bitnami-labs/sealed-secrets)  

---

© 2025 Auto-DevOps Project
