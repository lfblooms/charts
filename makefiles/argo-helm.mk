# ArgoCD Helm Chart Makefile
# Fork: lfblooms/argoproj.argo-helm
# Upstream: argoproj/argo-helm

ARGOCD_CHART_PATH := forks/argo-helm/charts/argo-cd
ARGOCD_RELEASE := argocd
ARGOCD_NAMESPACE := argocd
ARGOCD_VALUES_BASE := configs/values/argo-cd/base.yaml
ARGOCD_VALUES_CTX := configs/values/argo-cd/$(CONTEXT).yaml

# =============================================================================
# ARGOCD TARGETS
# =============================================================================

.PHONY: argocd-lint
argocd-lint: ## Lint ArgoCD chart
	@echo "$(GREEN)Linting ArgoCD chart...$(NC)"
	@$(HELM) lint $(ARGOCD_CHART_PATH)

.PHONY: argocd-template
argocd-template: ## Render ArgoCD templates
	@echo "$(GREEN)Rendering ArgoCD templates...$(NC)"
	@$(HELM) template $(ARGOCD_RELEASE) $(ARGOCD_CHART_PATH) \
		$(if $(wildcard $(ARGOCD_VALUES_BASE)),-f $(ARGOCD_VALUES_BASE)) \
		$(if $(wildcard $(ARGOCD_VALUES_CTX)),-f $(ARGOCD_VALUES_CTX))

.PHONY: argocd-deps
argocd-deps: ## Update ArgoCD chart dependencies
	@echo "$(GREEN)Updating ArgoCD dependencies...$(NC)"
	@$(HELM) dependency update $(ARGOCD_CHART_PATH)

.PHONY: argocd-install
argocd-install: ## Install ArgoCD
	@echo "$(GREEN)Installing ArgoCD...$(NC)"
	@$(KUBECTL) create namespace $(ARGOCD_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(ARGOCD_RELEASE) $(ARGOCD_CHART_PATH) \
		--namespace $(ARGOCD_NAMESPACE) \
		$(if $(wildcard $(ARGOCD_VALUES_BASE)),-f $(ARGOCD_VALUES_BASE)) \
		$(if $(wildcard $(ARGOCD_VALUES_CTX)),-f $(ARGOCD_VALUES_CTX)) \
		--wait

.PHONY: argocd-upgrade
argocd-upgrade: ## Upgrade ArgoCD
	@echo "$(GREEN)Upgrading ArgoCD...$(NC)"
	@$(HELM) upgrade $(ARGOCD_RELEASE) $(ARGOCD_CHART_PATH) \
		--namespace $(ARGOCD_NAMESPACE) \
		$(if $(wildcard $(ARGOCD_VALUES_BASE)),-f $(ARGOCD_VALUES_BASE)) \
		$(if $(wildcard $(ARGOCD_VALUES_CTX)),-f $(ARGOCD_VALUES_CTX)) \
		--wait

.PHONY: argocd-uninstall
argocd-uninstall: ## Uninstall ArgoCD
	@echo "$(RED)Uninstalling ArgoCD...$(NC)"
	@$(HELM) uninstall $(ARGOCD_RELEASE) --namespace $(ARGOCD_NAMESPACE) || true

.PHONY: argocd-status
argocd-status: ## Show ArgoCD status
	@echo "$(GREEN)ArgoCD Status:$(NC)"
	@$(HELM) status $(ARGOCD_RELEASE) --namespace $(ARGOCD_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(ARGOCD_NAMESPACE) 2>/dev/null || true

.PHONY: argocd-logs
argocd-logs: ## View ArgoCD server logs
	@$(KUBECTL) logs -n $(ARGOCD_NAMESPACE) -l app.kubernetes.io/name=argocd-server -f --tail=100

.PHONY: argocd-port-forward
argocd-port-forward: ## Port forward ArgoCD UI (localhost:8080)
	@echo "$(GREEN)ArgoCD UI available at https://localhost:8080$(NC)"
	@$(KUBECTL) port-forward svc/$(ARGOCD_RELEASE)-server -n $(ARGOCD_NAMESPACE) 8080:443

.PHONY: argocd-password
argocd-password: ## Get ArgoCD admin password
	@echo "$(GREEN)ArgoCD Admin Password:$(NC)"
	@$(KUBECTL) -n $(ARGOCD_NAMESPACE) get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

.PHONY: argocd-sync
argocd-sync: ## Sync fork with upstream
	@echo "$(GREEN)Syncing ArgoCD fork with upstream...$(NC)"
	@cd forks/argo-helm && git fetch upstream && git merge upstream/main --no-edit

# =============================================================================
# OCI PACKAGING & PUBLISHING
# =============================================================================

.PHONY: argocd-package
argocd-package: ## Package ArgoCD chart
	@$(PUSH_CHART) --chart $(ARGOCD_CHART_PATH) --package-only

.PHONY: argocd-push
argocd-push: ## Push ArgoCD chart to OCI registry (REGISTRY=local)
	@$(PUSH_CHART) --chart $(ARGOCD_CHART_PATH) --registry $(REGISTRY)

# =============================================================================
# MIRRORING (UPSTREAM → OCI REGISTRY)
# =============================================================================

.PHONY: argocd-mirror
argocd-mirror: ## Mirror ArgoCD chart + images (MIRROR_REGISTRY=docr, SINCE=<ver>)
	@$(MIRROR_CHART) --chart argo-cd $(if $(SINCE),--since $(SINCE)) --registry $(MIRROR_REGISTRY)

.PHONY: argocd-images
argocd-images: ## List container images in ArgoCD chart
	@$(EXTRACT_IMAGES) $(ARGOCD_CHART_PATH)
