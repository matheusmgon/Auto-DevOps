# Makefile para instalar ArgoCD e dar “bootstrap” na infra via GitOps

# Variáveis — sobrescreva antes de rodar se necessário
ARGOCD_SERVER   ?= argocd.example.com:443
GIT_REPO        ?= https://github.com/your-org/your-repo.git
ARGOCD_NAMESPACE?= argocd
BOOTSTRAP_APP   ?= infra-bootstrap

.PHONY: all install-argocd wait-argocd login-repo bootstrap-infra clean

all: install-argocd wait-argocd bootstrap-infra

## 1) Instala ArgoCD via Helm
install-argocd:
	@echo "==> Adding ArgoCD Helm repo..."
	helm repo add argo https://argoproj.github.io/argo-helm
	@echo "==> Creating namespace '$(ARGOCD_NAMESPACE)'..."
	kubectl create namespace $(ARGOCD_NAMESPACE) || true
	@echo "==> Installing ArgoCD..."
	helm install argocd argo/argo-cd \
	  --namespace $(ARGOCD_NAMESPACE) \
	  --set server.service.type=LoadBalancer \
	  --wait

## 2) Aguarda ArgoCD Server ficar disponível
wait-argocd:
	@echo "==> Waiting for ArgoCD server to be Available..."
	kubectl -n $(ARGOCD_NAMESPACE) wait \
	  --for=condition=Available deployment/argocd-server \
	  --timeout=120s

## 3) Faz login e registra o repositório no ArgoCD
login-repo: 
	@echo "==> Logging into ArgoCD..."
	argocd login $(ARGOCD_SERVER) \
	  --username admin \
	  --password $$(kubectl -n $(ARGOCD_NAMESPACE) get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d) \
	  --insecure
	@echo "==> Registering Git repo..."
	argocd repo add $(GIT_REPO) --name origin

## 4) Cria e faz sync do bootstrap (Application-of-Applications)
bootstrap-infra: login-repo
	@echo "==> Creating or updating bootstrap Application '$(BOOTSTRAP_APP)'..."
	argocd app create $(BOOTSTRAP_APP) \
	  --repo origin \
	  --path apps/bootstrap.yaml \
	  --dest-server https://kubernetes.default.svc \
	  --dest-namespace $(ARGOCD_NAMESPACE) \
	  --sync-policy automated \
	|| argocd app set $(BOOTSTRAP_APP) --sync-policy automated
	@echo "==> Syncing bootstrap Application..."
	argocd app sync $(BOOTSTRAP_APP)

## 5) Limpeza geral
clean:
	@echo "==> Deleting bootstrap Application..."
	argocd app delete $(BOOTSTRAP_APP) --cascade
	@echo "==> Uninstalling ArgoCD..."
	helm uninstall argocd -n $(ARGOCD_NAMESPACE)
	@echo "==> Deleting namespace '$(ARGOCD_NAMESPACE)'..."
	kubectl delete namespace $(ARGOCD_NAMESPACE) || true
