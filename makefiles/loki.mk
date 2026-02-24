# Loki Helm Chart Makefile
# Fork: lfblooms/grafana.loki
# Upstream: grafana/loki
# Chart: production/helm/loki

LOKI_CHART_PATH := forks/loki/production/helm/loki
LOKI_RELEASE := loki
LOKI_NAMESPACE := monitoring
LOKI_VALUES_BASE := configs/values/loki/base.yaml
LOKI_VALUES_CTX := configs/values/loki/$(CONTEXT).yaml

# =============================================================================
# LOKI TARGETS
# =============================================================================

.PHONY: loki-lint
loki-lint: ## Lint Loki chart
	@echo "$(GREEN)Linting Loki chart...$(NC)"
	@$(HELM) lint $(LOKI_CHART_PATH)

.PHONY: loki-template
loki-template: ## Render Loki templates
	@echo "$(GREEN)Rendering Loki templates...$(NC)"
	@$(HELM) template $(LOKI_RELEASE) $(LOKI_CHART_PATH) \
		$(if $(wildcard $(LOKI_VALUES_BASE)),-f $(LOKI_VALUES_BASE)) \
		$(if $(wildcard $(LOKI_VALUES_CTX)),-f $(LOKI_VALUES_CTX))

.PHONY: loki-deps
loki-deps: ## Update Loki chart dependencies
	@echo "$(GREEN)Updating Loki dependencies...$(NC)"
	@$(HELM) dependency update $(LOKI_CHART_PATH)

.PHONY: loki-install
loki-install: loki-deps ## Install Loki
	@echo "$(GREEN)Installing Loki...$(NC)"
	@$(KUBECTL) create namespace $(LOKI_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(LOKI_RELEASE) $(LOKI_CHART_PATH) \
		--namespace $(LOKI_NAMESPACE) \
		$(if $(wildcard $(LOKI_VALUES_BASE)),-f $(LOKI_VALUES_BASE)) \
		$(if $(wildcard $(LOKI_VALUES_CTX)),-f $(LOKI_VALUES_CTX)) \
		--wait --timeout 10m

.PHONY: loki-upgrade
loki-upgrade: loki-deps ## Upgrade Loki
	@echo "$(GREEN)Upgrading Loki...$(NC)"
	@$(HELM) upgrade $(LOKI_RELEASE) $(LOKI_CHART_PATH) \
		--namespace $(LOKI_NAMESPACE) \
		$(if $(wildcard $(LOKI_VALUES_BASE)),-f $(LOKI_VALUES_BASE)) \
		$(if $(wildcard $(LOKI_VALUES_CTX)),-f $(LOKI_VALUES_CTX)) \
		--wait --timeout 10m

.PHONY: loki-uninstall
loki-uninstall: ## Uninstall Loki
	@echo "$(RED)Uninstalling Loki...$(NC)"
	@$(HELM) uninstall $(LOKI_RELEASE) --namespace $(LOKI_NAMESPACE) || true

.PHONY: loki-status
loki-status: ## Show Loki status
	@echo "$(GREEN)Loki Status:$(NC)"
	@$(HELM) status $(LOKI_RELEASE) --namespace $(LOKI_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(LOKI_NAMESPACE) -l app.kubernetes.io/name=loki 2>/dev/null || true

.PHONY: loki-logs
loki-logs: ## View Loki logs
	@$(KUBECTL) logs -n $(LOKI_NAMESPACE) -l app.kubernetes.io/name=loki -f --tail=100

.PHONY: loki-sync
loki-sync: ## Sync fork with upstream
	@echo "$(GREEN)Syncing Loki fork with upstream...$(NC)"
	@cd forks/loki && git fetch upstream && git merge upstream/main --no-edit

# =============================================================================
# OCI PACKAGING & PUBLISHING
# =============================================================================

.PHONY: loki-package
loki-package: ## Package Loki chart
	@$(PUSH_CHART) --chart $(LOKI_CHART_PATH) --package-only

.PHONY: loki-push
loki-push: ## Push Loki chart to OCI registry (REGISTRY=local)
	@$(PUSH_CHART) --chart $(LOKI_CHART_PATH) --registry $(REGISTRY)

# =============================================================================
# MIRRORING (UPSTREAM → OCI REGISTRY)
# =============================================================================

.PHONY: loki-mirror
loki-mirror: ## Mirror Loki chart + images to DOCR (VERSION=<ver>)
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart loki $(if $(VERSION),--version $(VERSION))

.PHONY: loki-images
loki-images: ## List container images in Loki chart
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart loki --dry-run --images-only -o json | jq -r '.charts[].versions[].images[].source'
