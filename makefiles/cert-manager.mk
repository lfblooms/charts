# cert-manager Helm Chart Makefile
# Fork: MisterGrinvalds/cert-manager.cert-manager
# Upstream: cert-manager/cert-manager

CERTMANAGER_CHART_PATH := forks/cert-manager/deploy/charts/cert-manager
CERTMANAGER_RELEASE := cert-manager
CERTMANAGER_NAMESPACE := cert-manager
CERTMANAGER_VALUES_BASE := configs/values/cert-manager/base.yaml
CERTMANAGER_VALUES_CTX := configs/values/cert-manager/$(CONTEXT).yaml

# =============================================================================
# CERT-MANAGER TARGETS
# =============================================================================

.PHONY: cert-manager-lint
cert-manager-lint: ## Lint cert-manager chart
	@echo "$(GREEN)Linting cert-manager chart...$(NC)"
	@$(HELM) lint $(CERTMANAGER_CHART_PATH)

.PHONY: cert-manager-template
cert-manager-template: ## Render cert-manager templates
	@echo "$(GREEN)Rendering cert-manager templates...$(NC)"
	@$(HELM) template $(CERTMANAGER_RELEASE) $(CERTMANAGER_CHART_PATH) \
		$(if $(wildcard $(CERTMANAGER_VALUES_BASE)),-f $(CERTMANAGER_VALUES_BASE)) \
		$(if $(wildcard $(CERTMANAGER_VALUES_CTX)),-f $(CERTMANAGER_VALUES_CTX))

.PHONY: cert-manager-deps
cert-manager-deps: ## Update cert-manager chart dependencies
	@echo "$(GREEN)Updating cert-manager dependencies...$(NC)"
	@$(HELM) dependency update $(CERTMANAGER_CHART_PATH)

.PHONY: cert-manager-install-crds
cert-manager-install-crds: ## Install cert-manager CRDs
	@echo "$(GREEN)Installing cert-manager CRDs...$(NC)"
	@$(KUBECTL) apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.crds.yaml

.PHONY: cert-manager-install
cert-manager-install: cert-manager-install-crds ## Install cert-manager
	@echo "$(GREEN)Installing cert-manager...$(NC)"
	@$(KUBECTL) create namespace $(CERTMANAGER_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(CERTMANAGER_RELEASE) $(CERTMANAGER_CHART_PATH) \
		--namespace $(CERTMANAGER_NAMESPACE) \
		$(if $(wildcard $(CERTMANAGER_VALUES_BASE)),-f $(CERTMANAGER_VALUES_BASE)) \
		$(if $(wildcard $(CERTMANAGER_VALUES_CTX)),-f $(CERTMANAGER_VALUES_CTX)) \
		--wait

.PHONY: cert-manager-upgrade
cert-manager-upgrade: ## Upgrade cert-manager
	@echo "$(GREEN)Upgrading cert-manager...$(NC)"
	@$(HELM) upgrade $(CERTMANAGER_RELEASE) $(CERTMANAGER_CHART_PATH) \
		--namespace $(CERTMANAGER_NAMESPACE) \
		$(if $(wildcard $(CERTMANAGER_VALUES_BASE)),-f $(CERTMANAGER_VALUES_BASE)) \
		$(if $(wildcard $(CERTMANAGER_VALUES_CTX)),-f $(CERTMANAGER_VALUES_CTX)) \
		--wait

.PHONY: cert-manager-uninstall
cert-manager-uninstall: ## Uninstall cert-manager
	@echo "$(RED)Uninstalling cert-manager...$(NC)"
	@$(HELM) uninstall $(CERTMANAGER_RELEASE) --namespace $(CERTMANAGER_NAMESPACE) || true

.PHONY: cert-manager-status
cert-manager-status: ## Show cert-manager status
	@echo "$(GREEN)cert-manager Status:$(NC)"
	@$(HELM) status $(CERTMANAGER_RELEASE) --namespace $(CERTMANAGER_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(CERTMANAGER_NAMESPACE) 2>/dev/null || true

.PHONY: cert-manager-logs
cert-manager-logs: ## View cert-manager logs
	@$(KUBECTL) logs -n $(CERTMANAGER_NAMESPACE) -l app.kubernetes.io/name=cert-manager -f --tail=100

.PHONY: cert-manager-sync
cert-manager-sync: ## Sync fork with upstream
	@echo "$(GREEN)Syncing cert-manager fork with upstream...$(NC)"
	@cd forks/cert-manager && git fetch upstream && git merge upstream/master --no-edit
