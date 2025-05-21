├── README.md
├── apps
│   ├── argocd.yaml
│   ├── cert-manager.yaml
│   ├── ingress-controller.yaml
│   ├── monitoring.yaml
│   └── sample-app.yaml
├── charts
│   └── sample-app
│       ├── Chart.yaml
│       ├── templates
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   └── ingress.yaml
│       └── values.yaml
└── dashboards
    └── sample-app-dashboard.json

README.md

# Kubernetes GitOps Project

## Overview
This project automates the deployment of a Sample Movie Database application and necessary infrastructure components using Kubernetes, Helm, and ArgoCD following GitOps principles.

## Requirements
- Kubernetes Cluster
- Helm
- kubectl
- ArgoCD

## Setup Instructions

### 1. Install ArgoCD
```bash
kubectl create namespace argocd
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd --namespace argocd

2. Deploy ArgoCD Applications

Apply the applications configurations to let ArgoCD manage them:

kubectl apply -f apps/

3. Access ArgoCD

Port-forward to access ArgoCD UI:

kubectl port-forward svc/argocd-server -n argocd 8080:443

Get the initial password:

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

Applications Managed by ArgoCD

Sample Movie Database

Nginx Ingress Controller

Cert-manager (Let's Encrypt)

Prometheus & Grafana (Monitoring and Dashboards included)


Secret Management

Secrets are managed using Sealed Secrets:

Encrypt secrets before committing to git using the kubeseal CLI.


Grafana Dashboards

Custom dashboard provided in dashboards/sample-app-dashboard.json. Grafana auto-import enabled via Helm.

Additional Resources

ArgoCD Documentation

Sealed Secrets Documentation



---

© 2025 DevOps Kubernetes Project

### Exemplo de Arquivo ArgoCD (apps/sample-app.yaml)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sample-app
  namespace: argocd
spec:
  destination:
    namespace: sample-app
    server: https://kubernetes.default.svc
  project: default
  source:
    repoURL: https://github.com/<your-repo>
    path: charts/sample-app
    targetRevision: main
  syncPolicy:
    automated:
      prune: true
      selfHeal: true

Sealed Secrets Exemplo

kubectl create secret generic mysecret --dry-run=client --from-literal=password='mypassword' -o json | kubeseal > sealed-secret.json

Grafana Dashboard

Save your Grafana dashboard JSON to dashboards/sample-app-dashboard.json. Include this in Grafana Helm values to auto-import.

grafana:
  dashboards:
    default:
      sample-app:
        json: |
{{ .Files.Get "dashboards/sample-app-dashboard.json" | indent 10 }}


---

# Auto-DevOps
# Auto-DevOps
