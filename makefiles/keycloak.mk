# Keycloak (Bitnami) Helm Chart Makefile
# Fork: MisterGrinvalds/bitnami.charts
# Upstream: bitnami/charts

KEYCLOAK_CHART_PATH := forks/bitnami-charts/bitnami/keycloak
KEYCLOAK_RELEASE := keycloak
KEYCLOAK_NAMESPACE := keycloak
KEYCLOAK_VALUES_BASE := configs/values/keycloak/base.yaml
KEYCLOAK_VALUES_CTX := configs/values/keycloak/$(CONTEXT).yaml

# =============================================================================
# KEYCLOAK TARGETS
# =============================================================================

.PHONY: keycloak-lint
keycloak-lint: ## Lint Keycloak chart
	@echo "$(GREEN)Linting Keycloak chart...$(NC)"
	@$(HELM) lint $(KEYCLOAK_CHART_PATH)

.PHONY: keycloak-template
keycloak-template: ## Render Keycloak templates
	@echo "$(GREEN)Rendering Keycloak templates...$(NC)"
	@$(HELM) template $(KEYCLOAK_RELEASE) $(KEYCLOAK_CHART_PATH) \
		$(if $(wildcard $(KEYCLOAK_VALUES_BASE)),-f $(KEYCLOAK_VALUES_BASE)) \
		$(if $(wildcard $(KEYCLOAK_VALUES_CTX)),-f $(KEYCLOAK_VALUES_CTX))

.PHONY: keycloak-deps
keycloak-deps: ## Update Keycloak chart dependencies
	@echo "$(GREEN)Updating Keycloak dependencies...$(NC)"
	@$(HELM) dependency update $(KEYCLOAK_CHART_PATH)

.PHONY: keycloak-install
keycloak-install: keycloak-deps ## Install Keycloak
	@echo "$(GREEN)Installing Keycloak...$(NC)"
	@$(KUBECTL) create namespace $(KEYCLOAK_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(KEYCLOAK_RELEASE) $(KEYCLOAK_CHART_PATH) \
		--namespace $(KEYCLOAK_NAMESPACE) \
		$(if $(wildcard $(KEYCLOAK_VALUES_BASE)),-f $(KEYCLOAK_VALUES_BASE)) \
		$(if $(wildcard $(KEYCLOAK_VALUES_CTX)),-f $(KEYCLOAK_VALUES_CTX)) \
		--wait --timeout 10m

.PHONY: keycloak-upgrade
keycloak-upgrade: keycloak-deps ## Upgrade Keycloak
	@echo "$(GREEN)Upgrading Keycloak...$(NC)"
	@$(HELM) upgrade $(KEYCLOAK_RELEASE) $(KEYCLOAK_CHART_PATH) \
		--namespace $(KEYCLOAK_NAMESPACE) \
		$(if $(wildcard $(KEYCLOAK_VALUES_BASE)),-f $(KEYCLOAK_VALUES_BASE)) \
		$(if $(wildcard $(KEYCLOAK_VALUES_CTX)),-f $(KEYCLOAK_VALUES_CTX)) \
		--wait --timeout 10m

.PHONY: keycloak-uninstall
keycloak-uninstall: ## Uninstall Keycloak
	@echo "$(RED)Uninstalling Keycloak...$(NC)"
	@$(HELM) uninstall $(KEYCLOAK_RELEASE) --namespace $(KEYCLOAK_NAMESPACE) || true

.PHONY: keycloak-status
keycloak-status: ## Show Keycloak status
	@echo "$(GREEN)Keycloak Status:$(NC)"
	@$(HELM) status $(KEYCLOAK_RELEASE) --namespace $(KEYCLOAK_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(KEYCLOAK_NAMESPACE) 2>/dev/null || true

.PHONY: keycloak-logs
keycloak-logs: ## View Keycloak logs
	@$(KUBECTL) logs -n $(KEYCLOAK_NAMESPACE) -l app.kubernetes.io/name=keycloak -f --tail=100

.PHONY: keycloak-port-forward
keycloak-port-forward: ## Port forward Keycloak UI (localhost:8080)
	@echo "$(GREEN)Keycloak UI available at http://localhost:8080$(NC)"
	@$(KUBECTL) port-forward svc/$(KEYCLOAK_RELEASE) -n $(KEYCLOAK_NAMESPACE) 8080:80

.PHONY: keycloak-admin-password
keycloak-admin-password: ## Get Keycloak admin password
	@echo "$(GREEN)Keycloak Admin Password:$(NC)"
	@$(KUBECTL) get secret -n $(KEYCLOAK_NAMESPACE) $(KEYCLOAK_RELEASE) -o jsonpath="{.data.admin-password}" | base64 -d; echo

.PHONY: keycloak-sync
keycloak-sync: ## Sync Bitnami fork with upstream
	@echo "$(GREEN)Syncing Bitnami charts fork with upstream...$(NC)"
	@cd forks/bitnami-charts && git fetch upstream && git merge upstream/main --no-edit
