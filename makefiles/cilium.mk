# Cilium Helm Chart Makefile
# Fork: lfblooms/cilium.cilium
# Upstream: cilium/cilium
# Chart source: install/kubernetes/cilium (monorepo)

CILIUM_CHART_PATH := forks/cilium/install/kubernetes/cilium
CILIUM_RELEASE := cilium
CILIUM_NAMESPACE := kube-system
CILIUM_VALUES_BASE := configs/values/cilium/base.yaml
CILIUM_VALUES_CTX := configs/values/cilium/$(CONTEXT).yaml

# =============================================================================
# CILIUM TARGETS
# =============================================================================

.PHONY: cilium-lint
cilium-lint: ## Lint Cilium chart
	@echo "$(GREEN)Linting Cilium chart...$(NC)"
	@$(HELM) lint $(CILIUM_CHART_PATH)

.PHONY: cilium-template
cilium-template: ## Render Cilium templates
	@echo "$(GREEN)Rendering Cilium templates...$(NC)"
	@$(HELM) template $(CILIUM_RELEASE) $(CILIUM_CHART_PATH) \
		$(if $(wildcard $(CILIUM_VALUES_BASE)),-f $(CILIUM_VALUES_BASE)) \
		$(if $(wildcard $(CILIUM_VALUES_CTX)),-f $(CILIUM_VALUES_CTX))

.PHONY: cilium-deps
cilium-deps: ## Update Cilium chart dependencies
	@echo "$(GREEN)Updating Cilium dependencies...$(NC)"
	@$(HELM) dependency update $(CILIUM_CHART_PATH)

.PHONY: cilium-install
cilium-install: ## Install Cilium
	@echo "$(GREEN)Installing Cilium...$(NC)"
	@$(HELM) upgrade --install $(CILIUM_RELEASE) $(CILIUM_CHART_PATH) \
		--namespace $(CILIUM_NAMESPACE) \
		$(if $(wildcard $(CILIUM_VALUES_BASE)),-f $(CILIUM_VALUES_BASE)) \
		$(if $(wildcard $(CILIUM_VALUES_CTX)),-f $(CILIUM_VALUES_CTX)) \
		--wait

.PHONY: cilium-upgrade
cilium-upgrade: ## Upgrade Cilium
	@echo "$(GREEN)Upgrading Cilium...$(NC)"
	@$(HELM) upgrade $(CILIUM_RELEASE) $(CILIUM_CHART_PATH) \
		--namespace $(CILIUM_NAMESPACE) \
		$(if $(wildcard $(CILIUM_VALUES_BASE)),-f $(CILIUM_VALUES_BASE)) \
		$(if $(wildcard $(CILIUM_VALUES_CTX)),-f $(CILIUM_VALUES_CTX)) \
		--wait

.PHONY: cilium-uninstall
cilium-uninstall: ## Uninstall Cilium
	@echo "$(RED)Uninstalling Cilium...$(NC)"
	@$(HELM) uninstall $(CILIUM_RELEASE) --namespace $(CILIUM_NAMESPACE) || true

.PHONY: cilium-status
cilium-status: ## Show Cilium status
	@echo "$(GREEN)Cilium Status:$(NC)"
	@$(HELM) status $(CILIUM_RELEASE) --namespace $(CILIUM_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(CILIUM_NAMESPACE) -l app.kubernetes.io/part-of=cilium 2>/dev/null || true

.PHONY: cilium-logs
cilium-logs: ## View Cilium agent logs
	@$(KUBECTL) logs -n $(CILIUM_NAMESPACE) -l k8s-app=cilium -f --tail=100

.PHONY: cilium-sync
cilium-sync: ## Sync fork with upstream
	@echo "$(GREEN)Syncing Cilium fork with upstream...$(NC)"
	@cd forks/cilium && git fetch upstream && git merge upstream/main --no-edit

# =============================================================================
# OCI PACKAGING & PUBLISHING
# =============================================================================

.PHONY: cilium-package
cilium-package: ## Package Cilium chart
	@$(PUSH_CHART) --chart $(CILIUM_CHART_PATH) --package-only

.PHONY: cilium-push
cilium-push: ## Push Cilium chart to OCI registry (REGISTRY=local)
	@$(PUSH_CHART) --chart $(CILIUM_CHART_PATH) --registry $(REGISTRY)

# =============================================================================
# MIRRORING (UPSTREAM → OCI REGISTRY)
# =============================================================================

.PHONY: cilium-mirror
cilium-mirror: ## Mirror Cilium chart + images to DOCR (VERSION=<ver>)
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart cilium $(if $(VERSION),--version $(VERSION))

.PHONY: cilium-images
cilium-images: ## List container images in Cilium chart
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart cilium --dry-run --images-only -o json | jq -r '.charts[].versions[].images[].source'
