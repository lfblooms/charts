# Grafana Helm Chart Makefile
# Fork: lfblooms/grafana-community.helm-charts
# Upstream: grafana-community/helm-charts
# Chart: charts/grafana

GRAFANA_CHART_PATH := forks/grafana-community-helm-charts/charts/grafana
GRAFANA_RELEASE := grafana
GRAFANA_NAMESPACE := monitoring
GRAFANA_VALUES_BASE := configs/values/grafana/base.yaml
GRAFANA_VALUES_CTX := configs/values/grafana/$(CONTEXT).yaml

# =============================================================================
# GRAFANA TARGETS
# =============================================================================

.PHONY: grafana-lint
grafana-lint: ## Lint Grafana chart
	@echo "$(GREEN)Linting Grafana chart...$(NC)"
	@$(HELM) lint $(GRAFANA_CHART_PATH)

.PHONY: grafana-template
grafana-template: ## Render Grafana templates
	@echo "$(GREEN)Rendering Grafana templates...$(NC)"
	@$(HELM) template $(GRAFANA_RELEASE) $(GRAFANA_CHART_PATH) \
		$(if $(wildcard $(GRAFANA_VALUES_BASE)),-f $(GRAFANA_VALUES_BASE)) \
		$(if $(wildcard $(GRAFANA_VALUES_CTX)),-f $(GRAFANA_VALUES_CTX))

.PHONY: grafana-deps
grafana-deps: ## Update Grafana chart dependencies
	@echo "$(GREEN)Updating Grafana dependencies...$(NC)"
	@$(HELM) dependency update $(GRAFANA_CHART_PATH)

.PHONY: grafana-install
grafana-install: ## Install Grafana
	@echo "$(GREEN)Installing Grafana...$(NC)"
	@$(KUBECTL) create namespace $(GRAFANA_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(GRAFANA_RELEASE) $(GRAFANA_CHART_PATH) \
		--namespace $(GRAFANA_NAMESPACE) \
		$(if $(wildcard $(GRAFANA_VALUES_BASE)),-f $(GRAFANA_VALUES_BASE)) \
		$(if $(wildcard $(GRAFANA_VALUES_CTX)),-f $(GRAFANA_VALUES_CTX)) \
		--wait

.PHONY: grafana-upgrade
grafana-upgrade: ## Upgrade Grafana
	@echo "$(GREEN)Upgrading Grafana...$(NC)"
	@$(HELM) upgrade $(GRAFANA_RELEASE) $(GRAFANA_CHART_PATH) \
		--namespace $(GRAFANA_NAMESPACE) \
		$(if $(wildcard $(GRAFANA_VALUES_BASE)),-f $(GRAFANA_VALUES_BASE)) \
		$(if $(wildcard $(GRAFANA_VALUES_CTX)),-f $(GRAFANA_VALUES_CTX)) \
		--wait

.PHONY: grafana-uninstall
grafana-uninstall: ## Uninstall Grafana
	@echo "$(RED)Uninstalling Grafana...$(NC)"
	@$(HELM) uninstall $(GRAFANA_RELEASE) --namespace $(GRAFANA_NAMESPACE) || true

.PHONY: grafana-status
grafana-status: ## Show Grafana status
	@echo "$(GREEN)Grafana Status:$(NC)"
	@$(HELM) status $(GRAFANA_RELEASE) --namespace $(GRAFANA_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(GRAFANA_NAMESPACE) -l app.kubernetes.io/name=grafana 2>/dev/null || true

.PHONY: grafana-logs
grafana-logs: ## View Grafana logs
	@$(KUBECTL) logs -n $(GRAFANA_NAMESPACE) -l app.kubernetes.io/name=grafana -f --tail=100

.PHONY: grafana-port-forward
grafana-port-forward: ## Port forward Grafana UI (localhost:3000)
	@echo "$(GREEN)Grafana UI available at http://localhost:3000$(NC)"
	@$(KUBECTL) port-forward svc/$(GRAFANA_RELEASE) -n $(GRAFANA_NAMESPACE) 3000:80

.PHONY: grafana-password
grafana-password: ## Get Grafana admin password
	@echo "$(GREEN)Grafana Admin Password:$(NC)"
	@$(KUBECTL) get secret -n $(GRAFANA_NAMESPACE) $(GRAFANA_RELEASE) -o jsonpath="{.data.admin-password}" | base64 -d; echo

.PHONY: grafana-sync
grafana-sync: ## Sync fork with upstream
	@echo "$(GREEN)Syncing grafana-community helm-charts fork with upstream...$(NC)"
	@cd forks/grafana-community-helm-charts && git fetch upstream && git merge upstream/main --no-edit

# =============================================================================
# OCI PACKAGING & PUBLISHING
# =============================================================================

.PHONY: grafana-package
grafana-package: ## Package Grafana chart
	@$(PUSH_CHART) --chart $(GRAFANA_CHART_PATH) --package-only

.PHONY: grafana-push
grafana-push: ## Push Grafana chart to OCI registry (REGISTRY=local)
	@$(PUSH_CHART) --chart $(GRAFANA_CHART_PATH) --registry $(REGISTRY)

# =============================================================================
# MIRRORING (UPSTREAM → OCI REGISTRY)
# =============================================================================

.PHONY: grafana-mirror
grafana-mirror: ## Mirror Grafana chart + images to DOCR (VERSION=<ver>)
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart grafana $(if $(VERSION),--version $(VERSION))

.PHONY: grafana-images
grafana-images: ## List container images in Grafana chart
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart grafana --dry-run --images-only -o json | jq -r '.charts[].versions[].images[].source'
