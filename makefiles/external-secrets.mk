# external-secrets Helm Chart Makefile
# Fork: MisterGrinvalds/external-secrets.external-secrets
# Upstream: external-secrets/external-secrets

EXTERNALSECRETS_CHART_PATH := forks/external-secrets/deploy/charts/external-secrets
EXTERNALSECRETS_RELEASE := external-secrets
EXTERNALSECRETS_NAMESPACE := external-secrets
EXTERNALSECRETS_VALUES_BASE := configs/values/external-secrets/base.yaml
EXTERNALSECRETS_VALUES_CTX := configs/values/external-secrets/$(CONTEXT).yaml

# =============================================================================
# EXTERNAL-SECRETS TARGETS
# =============================================================================

.PHONY: external-secrets-lint
external-secrets-lint: ## Lint external-secrets chart
	@echo "$(GREEN)Linting external-secrets chart...$(NC)"
	@$(HELM) lint $(EXTERNALSECRETS_CHART_PATH)

.PHONY: external-secrets-template
external-secrets-template: ## Render external-secrets templates
	@echo "$(GREEN)Rendering external-secrets templates...$(NC)"
	@$(HELM) template $(EXTERNALSECRETS_RELEASE) $(EXTERNALSECRETS_CHART_PATH) \
		$(if $(wildcard $(EXTERNALSECRETS_VALUES_BASE)),-f $(EXTERNALSECRETS_VALUES_BASE)) \
		$(if $(wildcard $(EXTERNALSECRETS_VALUES_CTX)),-f $(EXTERNALSECRETS_VALUES_CTX))

.PHONY: external-secrets-deps
external-secrets-deps: ## Update external-secrets chart dependencies
	@echo "$(GREEN)Updating external-secrets dependencies...$(NC)"
	@$(HELM) dependency update $(EXTERNALSECRETS_CHART_PATH)

.PHONY: external-secrets-install-crds
external-secrets-install-crds: ## Install external-secrets CRDs
	@echo "$(GREEN)Installing external-secrets CRDs...$(NC)"
	@$(HELM) upgrade --install external-secrets-crds $(EXTERNALSECRETS_CHART_PATH) \
		--namespace $(EXTERNALSECRETS_NAMESPACE) \
		--set installCRDs=true \
		--set webhook.create=false \
		--set certController.create=false

.PHONY: external-secrets-install
external-secrets-install: ## Install external-secrets
	@echo "$(GREEN)Installing external-secrets...$(NC)"
	@$(KUBECTL) create namespace $(EXTERNALSECRETS_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(EXTERNALSECRETS_RELEASE) $(EXTERNALSECRETS_CHART_PATH) \
		--namespace $(EXTERNALSECRETS_NAMESPACE) \
		$(if $(wildcard $(EXTERNALSECRETS_VALUES_BASE)),-f $(EXTERNALSECRETS_VALUES_BASE)) \
		$(if $(wildcard $(EXTERNALSECRETS_VALUES_CTX)),-f $(EXTERNALSECRETS_VALUES_CTX)) \
		--wait

.PHONY: external-secrets-upgrade
external-secrets-upgrade: ## Upgrade external-secrets
	@echo "$(GREEN)Upgrading external-secrets...$(NC)"
	@$(HELM) upgrade $(EXTERNALSECRETS_RELEASE) $(EXTERNALSECRETS_CHART_PATH) \
		--namespace $(EXTERNALSECRETS_NAMESPACE) \
		$(if $(wildcard $(EXTERNALSECRETS_VALUES_BASE)),-f $(EXTERNALSECRETS_VALUES_BASE)) \
		$(if $(wildcard $(EXTERNALSECRETS_VALUES_CTX)),-f $(EXTERNALSECRETS_VALUES_CTX)) \
		--wait

.PHONY: external-secrets-uninstall
external-secrets-uninstall: ## Uninstall external-secrets
	@echo "$(RED)Uninstalling external-secrets...$(NC)"
	@$(HELM) uninstall $(EXTERNALSECRETS_RELEASE) --namespace $(EXTERNALSECRETS_NAMESPACE) || true

.PHONY: external-secrets-status
external-secrets-status: ## Show external-secrets status
	@echo "$(GREEN)external-secrets Status:$(NC)"
	@$(HELM) status $(EXTERNALSECRETS_RELEASE) --namespace $(EXTERNALSECRETS_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(EXTERNALSECRETS_NAMESPACE) 2>/dev/null || true

.PHONY: external-secrets-logs
external-secrets-logs: ## View external-secrets logs
	@$(KUBECTL) logs -n $(EXTERNALSECRETS_NAMESPACE) -l app.kubernetes.io/name=external-secrets -f --tail=100

.PHONY: external-secrets-sync
external-secrets-sync: ## Sync fork with upstream
	@echo "$(GREEN)Syncing external-secrets fork with upstream...$(NC)"
	@cd forks/external-secrets && git fetch upstream && git merge upstream/main --no-edit
