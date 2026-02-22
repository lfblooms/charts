# Harbor Helm Chart Makefile
# Fork: lfblooms/goharbor.harbor-helm
# Upstream: goharbor/harbor-helm

HARBOR_CHART_PATH := forks/harbor-helm
HARBOR_RELEASE := harbor
HARBOR_NAMESPACE := harbor
HARBOR_VALUES_BASE := configs/values/harbor/base.yaml
HARBOR_VALUES_CTX := configs/values/harbor/$(CONTEXT).yaml

# =============================================================================
# HARBOR TARGETS
# =============================================================================

.PHONY: harbor-lint
harbor-lint: ## Lint Harbor chart
	@echo "$(GREEN)Linting Harbor chart...$(NC)"
	@$(HELM) lint $(HARBOR_CHART_PATH)

.PHONY: harbor-template
harbor-template: ## Render Harbor templates
	@echo "$(GREEN)Rendering Harbor templates...$(NC)"
	@$(HELM) template $(HARBOR_RELEASE) $(HARBOR_CHART_PATH) \
		$(if $(wildcard $(HARBOR_VALUES_BASE)),-f $(HARBOR_VALUES_BASE)) \
		$(if $(wildcard $(HARBOR_VALUES_CTX)),-f $(HARBOR_VALUES_CTX))

.PHONY: harbor-deps
harbor-deps: ## Update Harbor chart dependencies
	@echo "$(GREEN)Updating Harbor dependencies...$(NC)"
	@$(HELM) dependency update $(HARBOR_CHART_PATH)

.PHONY: harbor-install
harbor-install: harbor-deps ## Install Harbor
	@echo "$(GREEN)Installing Harbor...$(NC)"
	@$(KUBECTL) create namespace $(HARBOR_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(HARBOR_RELEASE) $(HARBOR_CHART_PATH) \
		--namespace $(HARBOR_NAMESPACE) \
		$(if $(wildcard $(HARBOR_VALUES_BASE)),-f $(HARBOR_VALUES_BASE)) \
		$(if $(wildcard $(HARBOR_VALUES_CTX)),-f $(HARBOR_VALUES_CTX)) \
		--wait --timeout 10m

.PHONY: harbor-upgrade
harbor-upgrade: harbor-deps ## Upgrade Harbor
	@echo "$(GREEN)Upgrading Harbor...$(NC)"
	@$(HELM) upgrade $(HARBOR_RELEASE) $(HARBOR_CHART_PATH) \
		--namespace $(HARBOR_NAMESPACE) \
		$(if $(wildcard $(HARBOR_VALUES_BASE)),-f $(HARBOR_VALUES_BASE)) \
		$(if $(wildcard $(HARBOR_VALUES_CTX)),-f $(HARBOR_VALUES_CTX)) \
		--wait --timeout 10m

.PHONY: harbor-uninstall
harbor-uninstall: ## Uninstall Harbor
	@echo "$(RED)Uninstalling Harbor...$(NC)"
	@$(HELM) uninstall $(HARBOR_RELEASE) --namespace $(HARBOR_NAMESPACE) || true

.PHONY: harbor-status
harbor-status: ## Show Harbor status
	@echo "$(GREEN)Harbor Status:$(NC)"
	@$(HELM) status $(HARBOR_RELEASE) --namespace $(HARBOR_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(HARBOR_NAMESPACE) 2>/dev/null || true

.PHONY: harbor-logs
harbor-logs: ## View Harbor core logs
	@$(KUBECTL) logs -n $(HARBOR_NAMESPACE) -l component=core -f --tail=100

.PHONY: harbor-port-forward
harbor-port-forward: ## Port forward Harbor UI (localhost:8080)
	@echo "$(GREEN)Harbor UI available at https://localhost:8080$(NC)"
	@echo "$(YELLOW)Default credentials: admin / Harbor12345$(NC)"
	@$(KUBECTL) port-forward svc/$(HARBOR_RELEASE)-portal -n $(HARBOR_NAMESPACE) 8080:80

.PHONY: harbor-sync
harbor-sync: ## Sync fork with upstream
	@echo "$(GREEN)Syncing Harbor fork with upstream...$(NC)"
	@cd forks/harbor-helm && git fetch upstream && git merge upstream/main --no-edit

# =============================================================================
# OCI PACKAGING & PUBLISHING
# =============================================================================

.PHONY: harbor-package
harbor-package: ## Package Harbor chart
	@$(PUSH_CHART) --chart $(HARBOR_CHART_PATH) --package-only

.PHONY: harbor-push
harbor-push: ## Push Harbor chart to OCI registry (REGISTRY=local)
	@$(PUSH_CHART) --chart $(HARBOR_CHART_PATH) --registry $(REGISTRY)

# =============================================================================
# MIRRORING (UPSTREAM → OCI REGISTRY)
# =============================================================================

.PHONY: harbor-mirror
harbor-mirror: ## Mirror Harbor chart + images (MIRROR_REGISTRY=docr, SINCE=<ver>)
	@$(MIRROR_CHART) --chart harbor $(if $(SINCE),--since $(SINCE)) --registry $(MIRROR_REGISTRY)

.PHONY: harbor-images
harbor-images: ## List container images in Harbor chart
	@$(EXTRACT_IMAGES) $(HARBOR_CHART_PATH)
