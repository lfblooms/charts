# Nextcloud Helm Chart Makefile
# Fork: lfblooms/nextcloud.helm
# Upstream: nextcloud/helm

NEXTCLOUD_CHART_PATH := forks/nextcloud-helm/charts/nextcloud
NEXTCLOUD_RELEASE := nextcloud
NEXTCLOUD_NAMESPACE := nextcloud
NEXTCLOUD_VALUES_BASE := configs/values/nextcloud/base.yaml
NEXTCLOUD_VALUES_CTX := configs/values/nextcloud/$(CONTEXT).yaml

# =============================================================================
# NEXTCLOUD TARGETS
# =============================================================================

.PHONY: nextcloud-lint
nextcloud-lint: ## Lint Nextcloud chart
	@echo "$(GREEN)Linting Nextcloud chart...$(NC)"
	@$(HELM) lint $(NEXTCLOUD_CHART_PATH)

.PHONY: nextcloud-template
nextcloud-template: ## Render Nextcloud templates
	@echo "$(GREEN)Rendering Nextcloud templates...$(NC)"
	@$(HELM) template $(NEXTCLOUD_RELEASE) $(NEXTCLOUD_CHART_PATH) \
		$(if $(wildcard $(NEXTCLOUD_VALUES_BASE)),-f $(NEXTCLOUD_VALUES_BASE)) \
		$(if $(wildcard $(NEXTCLOUD_VALUES_CTX)),-f $(NEXTCLOUD_VALUES_CTX))

.PHONY: nextcloud-deps
nextcloud-deps: ## Update Nextcloud chart dependencies
	@echo "$(GREEN)Updating Nextcloud dependencies...$(NC)"
	@$(HELM) dependency update $(NEXTCLOUD_CHART_PATH)

.PHONY: nextcloud-install
nextcloud-install: nextcloud-deps ## Install Nextcloud
	@echo "$(GREEN)Installing Nextcloud...$(NC)"
	@$(KUBECTL) create namespace $(NEXTCLOUD_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(NEXTCLOUD_RELEASE) $(NEXTCLOUD_CHART_PATH) \
		--namespace $(NEXTCLOUD_NAMESPACE) \
		$(if $(wildcard $(NEXTCLOUD_VALUES_BASE)),-f $(NEXTCLOUD_VALUES_BASE)) \
		$(if $(wildcard $(NEXTCLOUD_VALUES_CTX)),-f $(NEXTCLOUD_VALUES_CTX)) \
		--wait --timeout 10m

.PHONY: nextcloud-upgrade
nextcloud-upgrade: nextcloud-deps ## Upgrade Nextcloud
	@echo "$(GREEN)Upgrading Nextcloud...$(NC)"
	@$(HELM) upgrade $(NEXTCLOUD_RELEASE) $(NEXTCLOUD_CHART_PATH) \
		--namespace $(NEXTCLOUD_NAMESPACE) \
		$(if $(wildcard $(NEXTCLOUD_VALUES_BASE)),-f $(NEXTCLOUD_VALUES_BASE)) \
		$(if $(wildcard $(NEXTCLOUD_VALUES_CTX)),-f $(NEXTCLOUD_VALUES_CTX)) \
		--wait --timeout 10m

.PHONY: nextcloud-uninstall
nextcloud-uninstall: ## Uninstall Nextcloud
	@echo "$(RED)Uninstalling Nextcloud...$(NC)"
	@$(HELM) uninstall $(NEXTCLOUD_RELEASE) --namespace $(NEXTCLOUD_NAMESPACE) || true

.PHONY: nextcloud-status
nextcloud-status: ## Show Nextcloud status
	@echo "$(GREEN)Nextcloud Status:$(NC)"
	@$(HELM) status $(NEXTCLOUD_RELEASE) --namespace $(NEXTCLOUD_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(NEXTCLOUD_NAMESPACE) 2>/dev/null || true

.PHONY: nextcloud-logs
nextcloud-logs: ## View Nextcloud logs
	@$(KUBECTL) logs -n $(NEXTCLOUD_NAMESPACE) -l app.kubernetes.io/name=nextcloud -f --tail=100

.PHONY: nextcloud-port-forward
nextcloud-port-forward: ## Port forward Nextcloud (localhost:8080)
	@echo "$(GREEN)Nextcloud available at http://localhost:8080$(NC)"
	@$(KUBECTL) port-forward svc/$(NEXTCLOUD_RELEASE) -n $(NEXTCLOUD_NAMESPACE) 8080:8080

.PHONY: nextcloud-sync
nextcloud-sync: ## Sync fork with upstream
	@echo "$(GREEN)Syncing Nextcloud helm fork with upstream...$(NC)"
	@cd forks/nextcloud-helm && git fetch upstream && git merge upstream/main --no-edit

# =============================================================================
# OCI PACKAGING & PUBLISHING
# =============================================================================

.PHONY: nextcloud-package
nextcloud-package: ## Package Nextcloud chart
	@$(PUSH_CHART) --chart $(NEXTCLOUD_CHART_PATH) --package-only

.PHONY: nextcloud-push
nextcloud-push: ## Push Nextcloud chart to OCI registry (REGISTRY=local)
	@$(PUSH_CHART) --chart $(NEXTCLOUD_CHART_PATH) --registry $(REGISTRY)

# =============================================================================
# MIRRORING (UPSTREAM → OCI REGISTRY)
# =============================================================================

.PHONY: nextcloud-mirror
nextcloud-mirror: ## Mirror Nextcloud chart + images (MIRROR_REGISTRY=docr, SINCE=<ver>)
	@$(MIRROR_CHART) --chart nextcloud $(if $(SINCE),--since $(SINCE)) --registry $(MIRROR_REGISTRY)

.PHONY: nextcloud-images
nextcloud-images: ## List container images in Nextcloud chart
	@$(EXTRACT_IMAGES) $(NEXTCLOUD_CHART_PATH)
