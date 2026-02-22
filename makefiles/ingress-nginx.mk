# ingress-nginx Helm Chart Makefile
# Fork: lfblooms/kubernetes.ingress-nginx
# Upstream: kubernetes/ingress-nginx

INGRESSNGINX_CHART_PATH := forks/ingress-nginx/charts/ingress-nginx
INGRESSNGINX_RELEASE := ingress-nginx
INGRESSNGINX_NAMESPACE := ingress-nginx
INGRESSNGINX_VALUES_BASE := configs/values/ingress-nginx/base.yaml
INGRESSNGINX_VALUES_CTX := configs/values/ingress-nginx/$(CONTEXT).yaml

# =============================================================================
# INGRESS-NGINX TARGETS
# =============================================================================

.PHONY: ingress-nginx-lint
ingress-nginx-lint: ## Lint ingress-nginx chart
	@echo "$(GREEN)Linting ingress-nginx chart...$(NC)"
	@$(HELM) lint $(INGRESSNGINX_CHART_PATH)

.PHONY: ingress-nginx-template
ingress-nginx-template: ## Render ingress-nginx templates
	@echo "$(GREEN)Rendering ingress-nginx templates...$(NC)"
	@$(HELM) template $(INGRESSNGINX_RELEASE) $(INGRESSNGINX_CHART_PATH) \
		$(if $(wildcard $(INGRESSNGINX_VALUES_BASE)),-f $(INGRESSNGINX_VALUES_BASE)) \
		$(if $(wildcard $(INGRESSNGINX_VALUES_CTX)),-f $(INGRESSNGINX_VALUES_CTX))

.PHONY: ingress-nginx-deps
ingress-nginx-deps: ## Update ingress-nginx chart dependencies
	@echo "$(GREEN)Updating ingress-nginx dependencies...$(NC)"
	@$(HELM) dependency update $(INGRESSNGINX_CHART_PATH)

.PHONY: ingress-nginx-install
ingress-nginx-install: ## Install ingress-nginx
	@echo "$(GREEN)Installing ingress-nginx...$(NC)"
	@$(KUBECTL) create namespace $(INGRESSNGINX_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(INGRESSNGINX_RELEASE) $(INGRESSNGINX_CHART_PATH) \
		--namespace $(INGRESSNGINX_NAMESPACE) \
		$(if $(wildcard $(INGRESSNGINX_VALUES_BASE)),-f $(INGRESSNGINX_VALUES_BASE)) \
		$(if $(wildcard $(INGRESSNGINX_VALUES_CTX)),-f $(INGRESSNGINX_VALUES_CTX)) \
		--wait

.PHONY: ingress-nginx-upgrade
ingress-nginx-upgrade: ## Upgrade ingress-nginx
	@echo "$(GREEN)Upgrading ingress-nginx...$(NC)"
	@$(HELM) upgrade $(INGRESSNGINX_RELEASE) $(INGRESSNGINX_CHART_PATH) \
		--namespace $(INGRESSNGINX_NAMESPACE) \
		$(if $(wildcard $(INGRESSNGINX_VALUES_BASE)),-f $(INGRESSNGINX_VALUES_BASE)) \
		$(if $(wildcard $(INGRESSNGINX_VALUES_CTX)),-f $(INGRESSNGINX_VALUES_CTX)) \
		--wait

.PHONY: ingress-nginx-uninstall
ingress-nginx-uninstall: ## Uninstall ingress-nginx
	@echo "$(RED)Uninstalling ingress-nginx...$(NC)"
	@$(HELM) uninstall $(INGRESSNGINX_RELEASE) --namespace $(INGRESSNGINX_NAMESPACE) || true

.PHONY: ingress-nginx-status
ingress-nginx-status: ## Show ingress-nginx status
	@echo "$(GREEN)ingress-nginx Status:$(NC)"
	@$(HELM) status $(INGRESSNGINX_RELEASE) --namespace $(INGRESSNGINX_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(INGRESSNGINX_NAMESPACE) 2>/dev/null || true

.PHONY: ingress-nginx-logs
ingress-nginx-logs: ## View ingress-nginx logs
	@$(KUBECTL) logs -n $(INGRESSNGINX_NAMESPACE) -l app.kubernetes.io/name=ingress-nginx -f --tail=100

.PHONY: ingress-nginx-sync
ingress-nginx-sync: ## Sync fork with upstream
	@echo "$(GREEN)Syncing ingress-nginx fork with upstream...$(NC)"
	@cd forks/ingress-nginx && git fetch upstream && git merge upstream/main --no-edit

# =============================================================================
# OCI PACKAGING & PUBLISHING
# =============================================================================

.PHONY: ingress-nginx-package
ingress-nginx-package: ## Package ingress-nginx chart
	@$(PUSH_CHART) --chart $(INGRESSNGINX_CHART_PATH) --package-only

.PHONY: ingress-nginx-push
ingress-nginx-push: ## Push ingress-nginx chart to OCI registry (REGISTRY=local)
	@$(PUSH_CHART) --chart $(INGRESSNGINX_CHART_PATH) --registry $(REGISTRY)

# =============================================================================
# MIRRORING (UPSTREAM → OCI REGISTRY)
# =============================================================================

.PHONY: ingress-nginx-mirror
ingress-nginx-mirror: ## Mirror ingress-nginx chart + images to DOCR (VERSION=<ver>)
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart ingress-nginx $(if $(VERSION),--version $(VERSION))

.PHONY: ingress-nginx-images
ingress-nginx-images: ## List container images in ingress-nginx chart
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart ingress-nginx --dry-run --images-only -o json | jq -r '.charts[].versions[].images[].source'
