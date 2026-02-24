# Mimir Helm Chart Makefile
# Fork: lfblooms/grafana.mimir
# Upstream: grafana/mimir
# Chart: operations/helm/charts/mimir-distributed

MIMIR_CHART_PATH := forks/mimir/operations/helm/charts/mimir-distributed
MIMIR_RELEASE := mimir
MIMIR_NAMESPACE := monitoring
MIMIR_VALUES_BASE := configs/values/mimir/base.yaml
MIMIR_VALUES_CTX := configs/values/mimir/$(CONTEXT).yaml

# =============================================================================
# MIMIR TARGETS
# =============================================================================

.PHONY: mimir-lint
mimir-lint: ## Lint Mimir chart
	@echo "$(GREEN)Linting Mimir chart...$(NC)"
	@$(HELM) lint $(MIMIR_CHART_PATH)

.PHONY: mimir-template
mimir-template: ## Render Mimir templates
	@echo "$(GREEN)Rendering Mimir templates...$(NC)"
	@$(HELM) template $(MIMIR_RELEASE) $(MIMIR_CHART_PATH) \
		$(if $(wildcard $(MIMIR_VALUES_BASE)),-f $(MIMIR_VALUES_BASE)) \
		$(if $(wildcard $(MIMIR_VALUES_CTX)),-f $(MIMIR_VALUES_CTX))

.PHONY: mimir-deps
mimir-deps: ## Update Mimir chart dependencies
	@echo "$(GREEN)Updating Mimir dependencies...$(NC)"
	@$(HELM) dependency update $(MIMIR_CHART_PATH)

.PHONY: mimir-install
mimir-install: mimir-deps ## Install Mimir
	@echo "$(GREEN)Installing Mimir...$(NC)"
	@$(KUBECTL) create namespace $(MIMIR_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(MIMIR_RELEASE) $(MIMIR_CHART_PATH) \
		--namespace $(MIMIR_NAMESPACE) \
		$(if $(wildcard $(MIMIR_VALUES_BASE)),-f $(MIMIR_VALUES_BASE)) \
		$(if $(wildcard $(MIMIR_VALUES_CTX)),-f $(MIMIR_VALUES_CTX)) \
		--wait --timeout 10m

.PHONY: mimir-upgrade
mimir-upgrade: mimir-deps ## Upgrade Mimir
	@echo "$(GREEN)Upgrading Mimir...$(NC)"
	@$(HELM) upgrade $(MIMIR_RELEASE) $(MIMIR_CHART_PATH) \
		--namespace $(MIMIR_NAMESPACE) \
		$(if $(wildcard $(MIMIR_VALUES_BASE)),-f $(MIMIR_VALUES_BASE)) \
		$(if $(wildcard $(MIMIR_VALUES_CTX)),-f $(MIMIR_VALUES_CTX)) \
		--wait --timeout 10m

.PHONY: mimir-uninstall
mimir-uninstall: ## Uninstall Mimir
	@echo "$(RED)Uninstalling Mimir...$(NC)"
	@$(HELM) uninstall $(MIMIR_RELEASE) --namespace $(MIMIR_NAMESPACE) || true

.PHONY: mimir-status
mimir-status: ## Show Mimir status
	@echo "$(GREEN)Mimir Status:$(NC)"
	@$(HELM) status $(MIMIR_RELEASE) --namespace $(MIMIR_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(MIMIR_NAMESPACE) -l app.kubernetes.io/name=mimir 2>/dev/null || true

.PHONY: mimir-logs
mimir-logs: ## View Mimir logs
	@$(KUBECTL) logs -n $(MIMIR_NAMESPACE) -l app.kubernetes.io/name=mimir -f --tail=100

.PHONY: mimir-sync
mimir-sync: ## Sync fork with upstream
	@echo "$(GREEN)Syncing Mimir fork with upstream...$(NC)"
	@cd forks/mimir && git fetch upstream && git merge upstream/main --no-edit

# =============================================================================
# OCI PACKAGING & PUBLISHING
# =============================================================================

.PHONY: mimir-package
mimir-package: ## Package Mimir chart
	@$(PUSH_CHART) --chart $(MIMIR_CHART_PATH) --package-only

.PHONY: mimir-push
mimir-push: ## Push Mimir chart to OCI registry (REGISTRY=local)
	@$(PUSH_CHART) --chart $(MIMIR_CHART_PATH) --registry $(REGISTRY)

# =============================================================================
# MIRRORING (UPSTREAM → OCI REGISTRY)
# =============================================================================

.PHONY: mimir-mirror
mimir-mirror: ## Mirror Mimir chart + images to DOCR (VERSION=<ver>)
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart mimir-distributed $(if $(VERSION),--version $(VERSION))

.PHONY: mimir-images
mimir-images: ## List container images in Mimir chart
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart mimir-distributed --dry-run --images-only -o json | jq -r '.charts[].versions[].images[].source'
