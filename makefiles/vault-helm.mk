# Vault Helm Chart Makefile
# Fork: MisterGrinvalds/hashicorp.vault-helm
# Upstream: hashicorp/vault-helm

VAULT_CHART_PATH := forks/vault-helm
VAULT_RELEASE := vault
VAULT_NAMESPACE := vault
VAULT_VALUES_BASE := configs/values/vault/base.yaml
VAULT_VALUES_CTX := configs/values/vault/$(CONTEXT).yaml

# =============================================================================
# VAULT TARGETS
# =============================================================================

.PHONY: vault-lint
vault-lint: ## Lint Vault chart
	@echo "$(GREEN)Linting Vault chart...$(NC)"
	@$(HELM) lint $(VAULT_CHART_PATH)

.PHONY: vault-template
vault-template: ## Render Vault templates
	@echo "$(GREEN)Rendering Vault templates...$(NC)"
	@$(HELM) template $(VAULT_RELEASE) $(VAULT_CHART_PATH) \
		$(if $(wildcard $(VAULT_VALUES_BASE)),-f $(VAULT_VALUES_BASE)) \
		$(if $(wildcard $(VAULT_VALUES_CTX)),-f $(VAULT_VALUES_CTX))

.PHONY: vault-deps
vault-deps: ## Update Vault chart dependencies
	@echo "$(GREEN)Updating Vault dependencies...$(NC)"
	@$(HELM) dependency update $(VAULT_CHART_PATH)

.PHONY: vault-install
vault-install: ## Install Vault
	@echo "$(GREEN)Installing Vault...$(NC)"
	@$(KUBECTL) create namespace $(VAULT_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(VAULT_RELEASE) $(VAULT_CHART_PATH) \
		--namespace $(VAULT_NAMESPACE) \
		$(if $(wildcard $(VAULT_VALUES_BASE)),-f $(VAULT_VALUES_BASE)) \
		$(if $(wildcard $(VAULT_VALUES_CTX)),-f $(VAULT_VALUES_CTX)) \
		--wait

.PHONY: vault-upgrade
vault-upgrade: ## Upgrade Vault
	@echo "$(GREEN)Upgrading Vault...$(NC)"
	@$(HELM) upgrade $(VAULT_RELEASE) $(VAULT_CHART_PATH) \
		--namespace $(VAULT_NAMESPACE) \
		$(if $(wildcard $(VAULT_VALUES_BASE)),-f $(VAULT_VALUES_BASE)) \
		$(if $(wildcard $(VAULT_VALUES_CTX)),-f $(VAULT_VALUES_CTX)) \
		--wait

.PHONY: vault-uninstall
vault-uninstall: ## Uninstall Vault
	@echo "$(RED)Uninstalling Vault...$(NC)"
	@$(HELM) uninstall $(VAULT_RELEASE) --namespace $(VAULT_NAMESPACE) || true

.PHONY: vault-status
vault-status: ## Show Vault status
	@echo "$(GREEN)Vault Status:$(NC)"
	@$(HELM) status $(VAULT_RELEASE) --namespace $(VAULT_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(VAULT_NAMESPACE) 2>/dev/null || true

.PHONY: vault-logs
vault-logs: ## View Vault logs
	@$(KUBECTL) logs -n $(VAULT_NAMESPACE) -l app.kubernetes.io/name=vault -f --tail=100

.PHONY: vault-port-forward
vault-port-forward: ## Port forward Vault UI (localhost:8200)
	@echo "$(GREEN)Vault UI available at http://localhost:8200$(NC)"
	@$(KUBECTL) port-forward svc/$(VAULT_RELEASE) -n $(VAULT_NAMESPACE) 8200:8200

.PHONY: vault-init
vault-init: ## Initialize Vault (first time setup)
	@echo "$(GREEN)Initializing Vault...$(NC)"
	@$(KUBECTL) exec -n $(VAULT_NAMESPACE) $(VAULT_RELEASE)-0 -- vault operator init

.PHONY: vault-unseal
vault-unseal: ## Unseal Vault (requires unseal key)
	@echo "$(YELLOW)Enter unseal key:$(NC)"
	@$(KUBECTL) exec -it -n $(VAULT_NAMESPACE) $(VAULT_RELEASE)-0 -- vault operator unseal

.PHONY: vault-seal-status
vault-seal-status: ## Check Vault seal status
	@$(KUBECTL) exec -n $(VAULT_NAMESPACE) $(VAULT_RELEASE)-0 -- vault status || true

.PHONY: vault-sync
vault-sync: ## Sync fork with upstream
	@echo "$(GREEN)Syncing Vault fork with upstream...$(NC)"
	@cd forks/vault-helm && git fetch upstream && git merge upstream/main --no-edit
