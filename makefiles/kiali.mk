# Kiali Helm Chart Makefile
# Fork: lfblooms/kiali.helm-charts
# Upstream: kiali/helm-charts

KIALI_CHART_PATH := forks/kiali-helm-charts/kiali-operator
KIALI_RELEASE := kiali-operator
KIALI_NAMESPACE := kiali-operator
KIALI_VALUES_BASE := configs/values/kiali/base.yaml
KIALI_VALUES_CTX := configs/values/kiali/$(CONTEXT).yaml

# =============================================================================
# KIALI TARGETS
# =============================================================================

.PHONY: kiali-lint
kiali-lint: ## Lint Kiali operator chart
	@echo "$(GREEN)Linting Kiali operator chart...$(NC)"
	@$(HELM) lint $(KIALI_CHART_PATH)

.PHONY: kiali-template
kiali-template: ## Render Kiali operator templates
	@echo "$(GREEN)Rendering Kiali operator templates...$(NC)"
	@$(HELM) template $(KIALI_RELEASE) $(KIALI_CHART_PATH) \
		$(if $(wildcard $(KIALI_VALUES_BASE)),-f $(KIALI_VALUES_BASE)) \
		$(if $(wildcard $(KIALI_VALUES_CTX)),-f $(KIALI_VALUES_CTX))

.PHONY: kiali-deps
kiali-deps: ## Update Kiali operator chart dependencies
	@echo "$(GREEN)Updating Kiali operator dependencies...$(NC)"
	@$(HELM) dependency update $(KIALI_CHART_PATH)

.PHONY: kiali-install
kiali-install: ## Install Kiali operator
	@echo "$(GREEN)Installing Kiali operator...$(NC)"
	@$(KUBECTL) create namespace $(KIALI_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(KIALI_RELEASE) $(KIALI_CHART_PATH) \
		--namespace $(KIALI_NAMESPACE) \
		$(if $(wildcard $(KIALI_VALUES_BASE)),-f $(KIALI_VALUES_BASE)) \
		$(if $(wildcard $(KIALI_VALUES_CTX)),-f $(KIALI_VALUES_CTX)) \
		--wait

.PHONY: kiali-upgrade
kiali-upgrade: ## Upgrade Kiali operator
	@echo "$(GREEN)Upgrading Kiali operator...$(NC)"
	@$(HELM) upgrade $(KIALI_RELEASE) $(KIALI_CHART_PATH) \
		--namespace $(KIALI_NAMESPACE) \
		$(if $(wildcard $(KIALI_VALUES_BASE)),-f $(KIALI_VALUES_BASE)) \
		$(if $(wildcard $(KIALI_VALUES_CTX)),-f $(KIALI_VALUES_CTX)) \
		--wait

.PHONY: kiali-uninstall
kiali-uninstall: ## Uninstall Kiali operator
	@echo "$(RED)Uninstalling Kiali operator...$(NC)"
	@$(HELM) uninstall $(KIALI_RELEASE) --namespace $(KIALI_NAMESPACE) || true

.PHONY: kiali-status
kiali-status: ## Show Kiali operator status
	@echo "$(GREEN)Kiali Operator Status:$(NC)"
	@$(HELM) status $(KIALI_RELEASE) --namespace $(KIALI_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(KIALI_NAMESPACE) 2>/dev/null || true
	@echo ""
	@echo "$(GREEN)Kiali Server Status:$(NC)"
	@$(KUBECTL) get kiali -A 2>/dev/null || true

.PHONY: kiali-logs
kiali-logs: ## View Kiali operator logs
	@$(KUBECTL) logs -n $(KIALI_NAMESPACE) -l app.kubernetes.io/name=kiali-operator -f --tail=100

.PHONY: kiali-port-forward
kiali-port-forward: ## Port forward Kiali UI (localhost:20001)
	@echo "$(GREEN)Kiali UI available at http://localhost:20001$(NC)"
	@$(KUBECTL) port-forward svc/kiali -n istio-system 20001:20001

.PHONY: kiali-sync
kiali-sync: ## Sync fork with upstream
	@echo "$(GREEN)Syncing Kiali fork with upstream...$(NC)"
	@cd forks/kiali-helm-charts && git fetch upstream && git merge upstream/master --no-edit

# =============================================================================
# OCI PACKAGING & PUBLISHING
# =============================================================================

.PHONY: kiali-package
kiali-package: ## Package Kiali operator chart
	@$(PUSH_CHART) --chart $(KIALI_CHART_PATH) --package-only

.PHONY: kiali-push
kiali-push: ## Push Kiali operator chart to OCI registry (REGISTRY=local)
	@$(PUSH_CHART) --chart $(KIALI_CHART_PATH) --registry $(REGISTRY)

# =============================================================================
# MIRRORING (UPSTREAM → OCI REGISTRY)
# =============================================================================

.PHONY: kiali-mirror
kiali-mirror: ## Mirror Kiali chart + images (MIRROR_REGISTRY=docr, SINCE=<ver>)
	@$(MIRROR_CHART) --chart kiali-server $(if $(SINCE),--since $(SINCE)) --registry $(MIRROR_REGISTRY)

.PHONY: kiali-images
kiali-images: ## List container images in Kiali chart
	@$(EXTRACT_IMAGES) $(KIALI_CHART_PATH)
