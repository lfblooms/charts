# Vault Secrets Operator Helm Chart Makefile
# Fork: MisterGrinvalds/hashicorp.vault-secrets-operator
# Upstream: hashicorp/vault-secrets-operator

VAULTSO_CHART_PATH := forks/vault-secrets-operator/chart
VAULTSO_RELEASE := vault-secrets-operator
VAULTSO_NAMESPACE := vault-secrets-operator
VAULTSO_VALUES_BASE := configs/values/vault-secrets-operator/base.yaml
VAULTSO_VALUES_CTX := configs/values/vault-secrets-operator/$(CONTEXT).yaml

# =============================================================================
# VAULT SECRETS OPERATOR TARGETS
# =============================================================================

.PHONY: vault-secrets-operator-lint
vault-secrets-operator-lint: ## Lint Vault Secrets Operator chart
	@echo "$(GREEN)Linting Vault Secrets Operator chart...$(NC)"
	@$(HELM) lint $(VAULTSO_CHART_PATH)

.PHONY: vault-secrets-operator-template
vault-secrets-operator-template: ## Render Vault Secrets Operator templates
	@echo "$(GREEN)Rendering Vault Secrets Operator templates...$(NC)"
	@$(HELM) template $(VAULTSO_RELEASE) $(VAULTSO_CHART_PATH) \
		$(if $(wildcard $(VAULTSO_VALUES_BASE)),-f $(VAULTSO_VALUES_BASE)) \
		$(if $(wildcard $(VAULTSO_VALUES_CTX)),-f $(VAULTSO_VALUES_CTX))

.PHONY: vault-secrets-operator-deps
vault-secrets-operator-deps: ## Update Vault Secrets Operator chart dependencies
	@echo "$(GREEN)Updating Vault Secrets Operator dependencies...$(NC)"
	@$(HELM) dependency update $(VAULTSO_CHART_PATH)

.PHONY: vault-secrets-operator-install
vault-secrets-operator-install: ## Install Vault Secrets Operator
	@echo "$(GREEN)Installing Vault Secrets Operator...$(NC)"
	@$(KUBECTL) create namespace $(VAULTSO_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(VAULTSO_RELEASE) $(VAULTSO_CHART_PATH) \
		--namespace $(VAULTSO_NAMESPACE) \
		$(if $(wildcard $(VAULTSO_VALUES_BASE)),-f $(VAULTSO_VALUES_BASE)) \
		$(if $(wildcard $(VAULTSO_VALUES_CTX)),-f $(VAULTSO_VALUES_CTX)) \
		--wait

.PHONY: vault-secrets-operator-upgrade
vault-secrets-operator-upgrade: ## Upgrade Vault Secrets Operator
	@echo "$(GREEN)Upgrading Vault Secrets Operator...$(NC)"
	@$(HELM) upgrade $(VAULTSO_RELEASE) $(VAULTSO_CHART_PATH) \
		--namespace $(VAULTSO_NAMESPACE) \
		$(if $(wildcard $(VAULTSO_VALUES_BASE)),-f $(VAULTSO_VALUES_BASE)) \
		$(if $(wildcard $(VAULTSO_VALUES_CTX)),-f $(VAULTSO_VALUES_CTX)) \
		--wait

.PHONY: vault-secrets-operator-uninstall
vault-secrets-operator-uninstall: ## Uninstall Vault Secrets Operator
	@echo "$(RED)Uninstalling Vault Secrets Operator...$(NC)"
	@$(HELM) uninstall $(VAULTSO_RELEASE) --namespace $(VAULTSO_NAMESPACE) || true

.PHONY: vault-secrets-operator-status
vault-secrets-operator-status: ## Show Vault Secrets Operator status
	@echo "$(GREEN)Vault Secrets Operator Status:$(NC)"
	@$(HELM) status $(VAULTSO_RELEASE) --namespace $(VAULTSO_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(VAULTSO_NAMESPACE) 2>/dev/null || true

.PHONY: vault-secrets-operator-logs
vault-secrets-operator-logs: ## View Vault Secrets Operator logs
	@$(KUBECTL) logs -n $(VAULTSO_NAMESPACE) -l app.kubernetes.io/name=vault-secrets-operator -f --tail=100

.PHONY: vault-secrets-operator-sync
vault-secrets-operator-sync: ## Sync fork with upstream
	@echo "$(GREEN)Syncing Vault Secrets Operator fork with upstream...$(NC)"
	@cd forks/vault-secrets-operator && git fetch upstream && git merge upstream/main --no-edit
