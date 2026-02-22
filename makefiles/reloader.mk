# Reloader Helm Chart Makefile
# Fork: lfblooms/stakater.Reloader
# Upstream: stakater/Reloader

RELOADER_CHART_PATH := forks/reloader/deployments/kubernetes/chart/reloader
RELOADER_RELEASE := reloader
RELOADER_NAMESPACE := reloader
RELOADER_VALUES_BASE := configs/values/reloader/base.yaml
RELOADER_VALUES_CTX := configs/values/reloader/$(CONTEXT).yaml

# =============================================================================
# RELOADER TARGETS
# =============================================================================

.PHONY: reloader-lint
reloader-lint: ## Lint Reloader chart
	@echo "$(GREEN)Linting Reloader chart...$(NC)"
	@$(HELM) lint $(RELOADER_CHART_PATH)

.PHONY: reloader-template
reloader-template: ## Render Reloader templates
	@echo "$(GREEN)Rendering Reloader templates...$(NC)"
	@$(HELM) template $(RELOADER_RELEASE) $(RELOADER_CHART_PATH) \
		$(if $(wildcard $(RELOADER_VALUES_BASE)),-f $(RELOADER_VALUES_BASE)) \
		$(if $(wildcard $(RELOADER_VALUES_CTX)),-f $(RELOADER_VALUES_CTX))

.PHONY: reloader-deps
reloader-deps: ## Update Reloader chart dependencies
	@echo "$(GREEN)Updating Reloader dependencies...$(NC)"
	@$(HELM) dependency update $(RELOADER_CHART_PATH)

.PHONY: reloader-install
reloader-install: ## Install Reloader
	@echo "$(GREEN)Installing Reloader...$(NC)"
	@$(KUBECTL) create namespace $(RELOADER_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(RELOADER_RELEASE) $(RELOADER_CHART_PATH) \
		--namespace $(RELOADER_NAMESPACE) \
		$(if $(wildcard $(RELOADER_VALUES_BASE)),-f $(RELOADER_VALUES_BASE)) \
		$(if $(wildcard $(RELOADER_VALUES_CTX)),-f $(RELOADER_VALUES_CTX)) \
		--wait

.PHONY: reloader-upgrade
reloader-upgrade: ## Upgrade Reloader
	@echo "$(GREEN)Upgrading Reloader...$(NC)"
	@$(HELM) upgrade $(RELOADER_RELEASE) $(RELOADER_CHART_PATH) \
		--namespace $(RELOADER_NAMESPACE) \
		$(if $(wildcard $(RELOADER_VALUES_BASE)),-f $(RELOADER_VALUES_BASE)) \
		$(if $(wildcard $(RELOADER_VALUES_CTX)),-f $(RELOADER_VALUES_CTX)) \
		--wait

.PHONY: reloader-uninstall
reloader-uninstall: ## Uninstall Reloader
	@echo "$(RED)Uninstalling Reloader...$(NC)"
	@$(HELM) uninstall $(RELOADER_RELEASE) --namespace $(RELOADER_NAMESPACE) || true

.PHONY: reloader-status
reloader-status: ## Show Reloader status
	@echo "$(GREEN)Reloader Status:$(NC)"
	@$(HELM) status $(RELOADER_RELEASE) --namespace $(RELOADER_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(RELOADER_NAMESPACE) 2>/dev/null || true

.PHONY: reloader-logs
reloader-logs: ## View Reloader logs
	@$(KUBECTL) logs -n $(RELOADER_NAMESPACE) -l app.kubernetes.io/name=reloader -f --tail=100

.PHONY: reloader-sync
reloader-sync: ## Sync fork with upstream
	@echo "$(GREEN)Syncing Reloader fork with upstream...$(NC)"
	@cd forks/reloader && git fetch upstream && git merge upstream/master --no-edit

# =============================================================================
# OCI PACKAGING & PUBLISHING
# =============================================================================

.PHONY: reloader-package
reloader-package: ## Package Reloader chart
	@$(PUSH_CHART) --chart $(RELOADER_CHART_PATH) --package-only

.PHONY: reloader-push
reloader-push: ## Push Reloader chart to OCI registry (REGISTRY=local)
	@$(PUSH_CHART) --chart $(RELOADER_CHART_PATH) --registry $(REGISTRY)

# =============================================================================
# MIRRORING (UPSTREAM → OCI REGISTRY)
# =============================================================================

.PHONY: reloader-mirror
reloader-mirror: ## Mirror Reloader chart + images to DOCR (VERSION=<ver>)
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart reloader $(if $(VERSION),--version $(VERSION))

.PHONY: reloader-images
reloader-images: ## List container images in Reloader chart
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart reloader --dry-run --images-only -o json | jq -r '.charts[].versions[].images[].source'
