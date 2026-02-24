# Tempo Helm Chart Makefile
# Fork: lfblooms/grafana-community.helm-charts
# Upstream: grafana-community/helm-charts
# Chart: charts/tempo

TEMPO_CHART_PATH := forks/grafana-community-helm-charts/charts/tempo
TEMPO_RELEASE := tempo
TEMPO_NAMESPACE := monitoring
TEMPO_VALUES_BASE := configs/values/tempo/base.yaml
TEMPO_VALUES_CTX := configs/values/tempo/$(CONTEXT).yaml

# =============================================================================
# TEMPO TARGETS
# =============================================================================

.PHONY: tempo-lint
tempo-lint: ## Lint Tempo chart
	@echo "$(GREEN)Linting Tempo chart...$(NC)"
	@$(HELM) lint $(TEMPO_CHART_PATH)

.PHONY: tempo-template
tempo-template: ## Render Tempo templates
	@echo "$(GREEN)Rendering Tempo templates...$(NC)"
	@$(HELM) template $(TEMPO_RELEASE) $(TEMPO_CHART_PATH) \
		$(if $(wildcard $(TEMPO_VALUES_BASE)),-f $(TEMPO_VALUES_BASE)) \
		$(if $(wildcard $(TEMPO_VALUES_CTX)),-f $(TEMPO_VALUES_CTX))

.PHONY: tempo-deps
tempo-deps: ## Update Tempo chart dependencies
	@echo "$(GREEN)Updating Tempo dependencies...$(NC)"
	@$(HELM) dependency update $(TEMPO_CHART_PATH)

.PHONY: tempo-install
tempo-install: ## Install Tempo
	@echo "$(GREEN)Installing Tempo...$(NC)"
	@$(KUBECTL) create namespace $(TEMPO_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(TEMPO_RELEASE) $(TEMPO_CHART_PATH) \
		--namespace $(TEMPO_NAMESPACE) \
		$(if $(wildcard $(TEMPO_VALUES_BASE)),-f $(TEMPO_VALUES_BASE)) \
		$(if $(wildcard $(TEMPO_VALUES_CTX)),-f $(TEMPO_VALUES_CTX)) \
		--wait

.PHONY: tempo-upgrade
tempo-upgrade: ## Upgrade Tempo
	@echo "$(GREEN)Upgrading Tempo...$(NC)"
	@$(HELM) upgrade $(TEMPO_RELEASE) $(TEMPO_CHART_PATH) \
		--namespace $(TEMPO_NAMESPACE) \
		$(if $(wildcard $(TEMPO_VALUES_BASE)),-f $(TEMPO_VALUES_BASE)) \
		$(if $(wildcard $(TEMPO_VALUES_CTX)),-f $(TEMPO_VALUES_CTX)) \
		--wait

.PHONY: tempo-uninstall
tempo-uninstall: ## Uninstall Tempo
	@echo "$(RED)Uninstalling Tempo...$(NC)"
	@$(HELM) uninstall $(TEMPO_RELEASE) --namespace $(TEMPO_NAMESPACE) || true

.PHONY: tempo-status
tempo-status: ## Show Tempo status
	@echo "$(GREEN)Tempo Status:$(NC)"
	@$(HELM) status $(TEMPO_RELEASE) --namespace $(TEMPO_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(TEMPO_NAMESPACE) -l app.kubernetes.io/name=tempo 2>/dev/null || true

.PHONY: tempo-logs
tempo-logs: ## View Tempo logs
	@$(KUBECTL) logs -n $(TEMPO_NAMESPACE) -l app.kubernetes.io/name=tempo -f --tail=100

.PHONY: tempo-sync
tempo-sync: ## Sync fork with upstream (shared with grafana chart)
	@echo "$(GREEN)Syncing grafana-community helm-charts fork with upstream...$(NC)"
	@cd forks/grafana-community-helm-charts && git fetch upstream && git merge upstream/main --no-edit

# =============================================================================
# OCI PACKAGING & PUBLISHING
# =============================================================================

.PHONY: tempo-package
tempo-package: ## Package Tempo chart
	@$(PUSH_CHART) --chart $(TEMPO_CHART_PATH) --package-only

.PHONY: tempo-push
tempo-push: ## Push Tempo chart to OCI registry (REGISTRY=local)
	@$(PUSH_CHART) --chart $(TEMPO_CHART_PATH) --registry $(REGISTRY)

# =============================================================================
# MIRRORING (UPSTREAM → OCI REGISTRY)
# =============================================================================

.PHONY: tempo-mirror
tempo-mirror: ## Mirror Tempo chart + images to DOCR (VERSION=<ver>)
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart tempo $(if $(VERSION),--version $(VERSION))

.PHONY: tempo-images
tempo-images: ## List container images in Tempo chart
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart tempo --dry-run --images-only -o json | jq -r '.charts[].versions[].images[].source'
