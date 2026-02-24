# Grafana Alloy Helm Chart Makefile
# Fork: lfblooms/grafana.alloy
# Upstream: grafana/alloy

ALLOY_CHART_PATH := forks/alloy/operations/helm/charts/alloy
ALLOY_RELEASE := alloy
ALLOY_NAMESPACE := monitoring
ALLOY_VALUES_BASE := configs/values/alloy/base.yaml
ALLOY_VALUES_CTX := configs/values/alloy/$(CONTEXT).yaml

# =============================================================================
# ALLOY TARGETS
# =============================================================================

.PHONY: alloy-lint
alloy-lint: ## Lint Alloy chart
	@echo "$(GREEN)Linting Alloy chart...$(NC)"
	@$(HELM) lint $(ALLOY_CHART_PATH)

.PHONY: alloy-template
alloy-template: ## Render Alloy templates
	@echo "$(GREEN)Rendering Alloy templates...$(NC)"
	@$(HELM) template $(ALLOY_RELEASE) $(ALLOY_CHART_PATH) \
		$(if $(wildcard $(ALLOY_VALUES_BASE)),-f $(ALLOY_VALUES_BASE)) \
		$(if $(wildcard $(ALLOY_VALUES_CTX)),-f $(ALLOY_VALUES_CTX))

.PHONY: alloy-deps
alloy-deps: ## Update Alloy chart dependencies
	@echo "$(GREEN)Updating Alloy dependencies...$(NC)"
	@$(HELM) dependency update $(ALLOY_CHART_PATH)

.PHONY: alloy-install
alloy-install: alloy-deps ## Install Alloy
	@echo "$(GREEN)Installing Alloy...$(NC)"
	@$(KUBECTL) create namespace $(ALLOY_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(ALLOY_RELEASE) $(ALLOY_CHART_PATH) \
		--namespace $(ALLOY_NAMESPACE) \
		$(if $(wildcard $(ALLOY_VALUES_BASE)),-f $(ALLOY_VALUES_BASE)) \
		$(if $(wildcard $(ALLOY_VALUES_CTX)),-f $(ALLOY_VALUES_CTX)) \
		--wait

.PHONY: alloy-upgrade
alloy-upgrade: alloy-deps ## Upgrade Alloy
	@echo "$(GREEN)Upgrading Alloy...$(NC)"
	@$(HELM) upgrade $(ALLOY_RELEASE) $(ALLOY_CHART_PATH) \
		--namespace $(ALLOY_NAMESPACE) \
		$(if $(wildcard $(ALLOY_VALUES_BASE)),-f $(ALLOY_VALUES_BASE)) \
		$(if $(wildcard $(ALLOY_VALUES_CTX)),-f $(ALLOY_VALUES_CTX)) \
		--wait

.PHONY: alloy-uninstall
alloy-uninstall: ## Uninstall Alloy
	@echo "$(RED)Uninstalling Alloy...$(NC)"
	@$(HELM) uninstall $(ALLOY_RELEASE) --namespace $(ALLOY_NAMESPACE) || true

.PHONY: alloy-status
alloy-status: ## Show Alloy status
	@echo "$(GREEN)Alloy Status:$(NC)"
	@$(HELM) status $(ALLOY_RELEASE) --namespace $(ALLOY_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(ALLOY_NAMESPACE) -l app.kubernetes.io/name=alloy 2>/dev/null || true

.PHONY: alloy-logs
alloy-logs: ## View Alloy logs
	@$(KUBECTL) logs -n $(ALLOY_NAMESPACE) -l app.kubernetes.io/name=alloy -f --tail=100

.PHONY: alloy-sync
alloy-sync: ## Sync fork with upstream
	@echo "$(GREEN)Syncing Alloy fork with upstream...$(NC)"
	@cd forks/alloy && git fetch upstream && git merge upstream/main --no-edit

# =============================================================================
# OCI PACKAGING & PUBLISHING
# =============================================================================

.PHONY: alloy-package
alloy-package: ## Package Alloy chart
	@$(PUSH_CHART) --chart $(ALLOY_CHART_PATH) --package-only

.PHONY: alloy-push
alloy-push: ## Push Alloy chart to OCI registry (REGISTRY=local)
	@$(PUSH_CHART) --chart $(ALLOY_CHART_PATH) --registry $(REGISTRY)

# =============================================================================
# MIRRORING (UPSTREAM → OCI REGISTRY)
# =============================================================================

.PHONY: alloy-mirror
alloy-mirror: ## Mirror Alloy chart + images to DOCR (VERSION=<ver>)
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart alloy $(if $(VERSION),--version $(VERSION))

.PHONY: alloy-images
alloy-images: ## List container images in Alloy chart
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart alloy --dry-run --images-only -o json | jq -r '.charts[].versions[].images[].source'
