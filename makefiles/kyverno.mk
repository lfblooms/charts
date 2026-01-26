# Kyverno Helm Chart Makefile
# Fork: MisterGrinvalds/kyverno.kyverno
# Upstream: kyverno/kyverno

KYVERNO_CHART_PATH := forks/kyverno/charts/kyverno
KYVERNO_RELEASE := kyverno
KYVERNO_NAMESPACE := kyverno
KYVERNO_VALUES_BASE := configs/values/kyverno/base.yaml
KYVERNO_VALUES_CTX := configs/values/kyverno/$(CONTEXT).yaml

# Kyverno Policies (optional)
KYVERNO_POLICIES_CHART_PATH := forks/kyverno/charts/kyverno-policies
KYVERNO_POLICIES_RELEASE := kyverno-policies
KYVERNO_POLICIES_VALUES_BASE := configs/values/kyverno-policies/base.yaml
KYVERNO_POLICIES_VALUES_CTX := configs/values/kyverno-policies/$(CONTEXT).yaml

# =============================================================================
# KYVERNO TARGETS
# =============================================================================

.PHONY: kyverno-lint
kyverno-lint: ## Lint Kyverno chart
	@echo "$(GREEN)Linting Kyverno chart...$(NC)"
	@$(HELM) lint $(KYVERNO_CHART_PATH)

.PHONY: kyverno-template
kyverno-template: ## Render Kyverno templates
	@echo "$(GREEN)Rendering Kyverno templates...$(NC)"
	@$(HELM) template $(KYVERNO_RELEASE) $(KYVERNO_CHART_PATH) \
		$(if $(wildcard $(KYVERNO_VALUES_BASE)),-f $(KYVERNO_VALUES_BASE)) \
		$(if $(wildcard $(KYVERNO_VALUES_CTX)),-f $(KYVERNO_VALUES_CTX))

.PHONY: kyverno-deps
kyverno-deps: ## Update Kyverno chart dependencies
	@echo "$(GREEN)Updating Kyverno dependencies...$(NC)"
	@$(HELM) dependency update $(KYVERNO_CHART_PATH)

.PHONY: kyverno-install
kyverno-install: ## Install Kyverno
	@echo "$(GREEN)Installing Kyverno...$(NC)"
	@$(KUBECTL) create namespace $(KYVERNO_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(KYVERNO_RELEASE) $(KYVERNO_CHART_PATH) \
		--namespace $(KYVERNO_NAMESPACE) \
		$(if $(wildcard $(KYVERNO_VALUES_BASE)),-f $(KYVERNO_VALUES_BASE)) \
		$(if $(wildcard $(KYVERNO_VALUES_CTX)),-f $(KYVERNO_VALUES_CTX)) \
		--wait

.PHONY: kyverno-upgrade
kyverno-upgrade: ## Upgrade Kyverno
	@echo "$(GREEN)Upgrading Kyverno...$(NC)"
	@$(HELM) upgrade $(KYVERNO_RELEASE) $(KYVERNO_CHART_PATH) \
		--namespace $(KYVERNO_NAMESPACE) \
		$(if $(wildcard $(KYVERNO_VALUES_BASE)),-f $(KYVERNO_VALUES_BASE)) \
		$(if $(wildcard $(KYVERNO_VALUES_CTX)),-f $(KYVERNO_VALUES_CTX)) \
		--wait

.PHONY: kyverno-uninstall
kyverno-uninstall: ## Uninstall Kyverno
	@echo "$(RED)Uninstalling Kyverno...$(NC)"
	@$(HELM) uninstall $(KYVERNO_RELEASE) --namespace $(KYVERNO_NAMESPACE) || true

.PHONY: kyverno-status
kyverno-status: ## Show Kyverno status
	@echo "$(GREEN)Kyverno Status:$(NC)"
	@$(HELM) status $(KYVERNO_RELEASE) --namespace $(KYVERNO_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(KYVERNO_NAMESPACE) 2>/dev/null || true

.PHONY: kyverno-logs
kyverno-logs: ## View Kyverno logs
	@$(KUBECTL) logs -n $(KYVERNO_NAMESPACE) -l app.kubernetes.io/name=kyverno -f --tail=100

# =============================================================================
# KYVERNO POLICIES TARGETS
# =============================================================================

.PHONY: kyverno-policies-lint
kyverno-policies-lint: ## Lint Kyverno policies chart
	@echo "$(GREEN)Linting Kyverno policies chart...$(NC)"
	@$(HELM) lint $(KYVERNO_POLICIES_CHART_PATH)

.PHONY: kyverno-policies-install
kyverno-policies-install: ## Install Kyverno policies
	@echo "$(GREEN)Installing Kyverno policies...$(NC)"
	@$(HELM) upgrade --install $(KYVERNO_POLICIES_RELEASE) $(KYVERNO_POLICIES_CHART_PATH) \
		--namespace $(KYVERNO_NAMESPACE) \
		$(if $(wildcard $(KYVERNO_POLICIES_VALUES_BASE)),-f $(KYVERNO_POLICIES_VALUES_BASE)) \
		$(if $(wildcard $(KYVERNO_POLICIES_VALUES_CTX)),-f $(KYVERNO_POLICIES_VALUES_CTX)) \
		--wait

.PHONY: kyverno-policies-uninstall
kyverno-policies-uninstall: ## Uninstall Kyverno policies
	@echo "$(RED)Uninstalling Kyverno policies...$(NC)"
	@$(HELM) uninstall $(KYVERNO_POLICIES_RELEASE) --namespace $(KYVERNO_NAMESPACE) || true

.PHONY: kyverno-sync
kyverno-sync: ## Sync fork with upstream
	@echo "$(GREEN)Syncing Kyverno fork with upstream...$(NC)"
	@cd forks/kyverno && git fetch upstream && git merge upstream/main --no-edit
