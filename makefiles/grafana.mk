# Grafana Helm Charts Makefile
# Fork: lfblooms/grafana.helm-charts
# Upstream: grafana/helm-charts
# Charts: grafana, loki, tempo, mimir-distributed

GRAFANA_FORK_PATH := forks/grafana-helm-charts/charts

# Grafana
GRAFANA_CHART_PATH := $(GRAFANA_FORK_PATH)/grafana
GRAFANA_RELEASE := grafana
GRAFANA_NAMESPACE := monitoring
GRAFANA_VALUES_BASE := configs/values/grafana/base.yaml
GRAFANA_VALUES_CTX := configs/values/grafana/$(CONTEXT).yaml

# Loki
LOKI_CHART_PATH := $(GRAFANA_FORK_PATH)/loki
LOKI_RELEASE := loki
LOKI_NAMESPACE := monitoring
LOKI_VALUES_BASE := configs/values/loki/base.yaml
LOKI_VALUES_CTX := configs/values/loki/$(CONTEXT).yaml

# Tempo
TEMPO_CHART_PATH := $(GRAFANA_FORK_PATH)/tempo
TEMPO_RELEASE := tempo
TEMPO_NAMESPACE := monitoring
TEMPO_VALUES_BASE := configs/values/tempo/base.yaml
TEMPO_VALUES_CTX := configs/values/tempo/$(CONTEXT).yaml

# Mimir
MIMIR_CHART_PATH := $(GRAFANA_FORK_PATH)/mimir-distributed
MIMIR_RELEASE := mimir
MIMIR_NAMESPACE := monitoring
MIMIR_VALUES_BASE := configs/values/mimir/base.yaml
MIMIR_VALUES_CTX := configs/values/mimir/$(CONTEXT).yaml

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

# =============================================================================
# LOKI TARGETS
# =============================================================================

.PHONY: loki-lint
loki-lint: ## Lint Loki chart
	@echo "$(GREEN)Linting Loki chart...$(NC)"
	@$(HELM) lint $(LOKI_CHART_PATH)

.PHONY: loki-template
loki-template: ## Render Loki templates
	@echo "$(GREEN)Rendering Loki templates...$(NC)"
	@$(HELM) template $(LOKI_RELEASE) $(LOKI_CHART_PATH) \
		$(if $(wildcard $(LOKI_VALUES_BASE)),-f $(LOKI_VALUES_BASE)) \
		$(if $(wildcard $(LOKI_VALUES_CTX)),-f $(LOKI_VALUES_CTX))

.PHONY: loki-deps
loki-deps: ## Update Loki chart dependencies
	@echo "$(GREEN)Updating Loki dependencies...$(NC)"
	@$(HELM) dependency update $(LOKI_CHART_PATH)

.PHONY: loki-install
loki-install: ## Install Loki
	@echo "$(GREEN)Installing Loki...$(NC)"
	@$(KUBECTL) create namespace $(LOKI_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(LOKI_RELEASE) $(LOKI_CHART_PATH) \
		--namespace $(LOKI_NAMESPACE) \
		$(if $(wildcard $(LOKI_VALUES_BASE)),-f $(LOKI_VALUES_BASE)) \
		$(if $(wildcard $(LOKI_VALUES_CTX)),-f $(LOKI_VALUES_CTX)) \
		--wait

.PHONY: loki-upgrade
loki-upgrade: ## Upgrade Loki
	@echo "$(GREEN)Upgrading Loki...$(NC)"
	@$(HELM) upgrade $(LOKI_RELEASE) $(LOKI_CHART_PATH) \
		--namespace $(LOKI_NAMESPACE) \
		$(if $(wildcard $(LOKI_VALUES_BASE)),-f $(LOKI_VALUES_BASE)) \
		$(if $(wildcard $(LOKI_VALUES_CTX)),-f $(LOKI_VALUES_CTX)) \
		--wait

.PHONY: loki-uninstall
loki-uninstall: ## Uninstall Loki
	@echo "$(RED)Uninstalling Loki...$(NC)"
	@$(HELM) uninstall $(LOKI_RELEASE) --namespace $(LOKI_NAMESPACE) || true

.PHONY: loki-status
loki-status: ## Show Loki status
	@echo "$(GREEN)Loki Status:$(NC)"
	@$(HELM) status $(LOKI_RELEASE) --namespace $(LOKI_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(LOKI_NAMESPACE) -l app.kubernetes.io/name=loki 2>/dev/null || true

.PHONY: loki-logs
loki-logs: ## View Loki logs
	@$(KUBECTL) logs -n $(LOKI_NAMESPACE) -l app.kubernetes.io/name=loki -f --tail=100

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

# =============================================================================
# MIMIR TARGETS
# =============================================================================

.PHONY: mimir-lint
mimir-lint: ## Lint Mimir chart
	@echo "$(GREEN)Linting Mimir chart...$(NC)"
	@$(HELM) lint $(MIMIR_CHART_PATH)

.PHONY: mimir-template
mimir-template: ## Render Mimir templates
	@echo "$(GREEN)Rendering Mimir templates...$(NC)"
	@$(HELM) template $(MIMIR_RELEASE) $(MIMIR_CHART_PATH) \
		$(if $(wildcard $(MIMIR_VALUES_BASE)),-f $(MIMIR_VALUES_BASE)) \
		$(if $(wildcard $(MIMIR_VALUES_CTX)),-f $(MIMIR_VALUES_CTX))

.PHONY: mimir-deps
mimir-deps: ## Update Mimir chart dependencies
	@echo "$(GREEN)Updating Mimir dependencies...$(NC)"
	@$(HELM) dependency update $(MIMIR_CHART_PATH)

.PHONY: mimir-install
mimir-install: ## Install Mimir
	@echo "$(GREEN)Installing Mimir...$(NC)"
	@$(KUBECTL) create namespace $(MIMIR_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(MIMIR_RELEASE) $(MIMIR_CHART_PATH) \
		--namespace $(MIMIR_NAMESPACE) \
		$(if $(wildcard $(MIMIR_VALUES_BASE)),-f $(MIMIR_VALUES_BASE)) \
		$(if $(wildcard $(MIMIR_VALUES_CTX)),-f $(MIMIR_VALUES_CTX)) \
		--wait

.PHONY: mimir-upgrade
mimir-upgrade: ## Upgrade Mimir
	@echo "$(GREEN)Upgrading Mimir...$(NC)"
	@$(HELM) upgrade $(MIMIR_RELEASE) $(MIMIR_CHART_PATH) \
		--namespace $(MIMIR_NAMESPACE) \
		$(if $(wildcard $(MIMIR_VALUES_BASE)),-f $(MIMIR_VALUES_BASE)) \
		$(if $(wildcard $(MIMIR_VALUES_CTX)),-f $(MIMIR_VALUES_CTX)) \
		--wait

.PHONY: mimir-uninstall
mimir-uninstall: ## Uninstall Mimir
	@echo "$(RED)Uninstalling Mimir...$(NC)"
	@$(HELM) uninstall $(MIMIR_RELEASE) --namespace $(MIMIR_NAMESPACE) || true

.PHONY: mimir-status
mimir-status: ## Show Mimir status
	@echo "$(GREEN)Mimir Status:$(NC)"
	@$(HELM) status $(MIMIR_RELEASE) --namespace $(MIMIR_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(MIMIR_NAMESPACE) -l app.kubernetes.io/name=mimir 2>/dev/null || true

.PHONY: mimir-logs
mimir-logs: ## View Mimir logs
	@$(KUBECTL) logs -n $(MIMIR_NAMESPACE) -l app.kubernetes.io/name=mimir -f --tail=100

# =============================================================================
# OBSERVABILITY STACK
# =============================================================================

.PHONY: observability-install
observability-install: grafana-install loki-install tempo-install ## Install full observability stack (Grafana + Loki + Tempo)

.PHONY: observability-uninstall
observability-uninstall: grafana-uninstall loki-uninstall tempo-uninstall ## Uninstall full observability stack

.PHONY: observability-status
observability-status: grafana-status loki-status tempo-status ## Show status of observability stack

# =============================================================================
# GRAFANA FORK SYNC
# =============================================================================

.PHONY: grafana-sync
grafana-sync: ## Sync fork with upstream
	@echo "$(GREEN)Syncing Grafana helm-charts fork with upstream...$(NC)"
	@cd forks/grafana-helm-charts && git fetch upstream && git merge upstream/main --no-edit

# =============================================================================
# OCI PACKAGING & PUBLISHING
# =============================================================================

.PHONY: grafana-package
grafana-package: ## Package Grafana chart
	@$(PUSH_CHART) --chart $(GRAFANA_CHART_PATH) --package-only

.PHONY: grafana-push
grafana-push: ## Push Grafana chart to OCI registry (REGISTRY=local)
	@$(PUSH_CHART) --chart $(GRAFANA_CHART_PATH) --registry $(REGISTRY)

.PHONY: loki-package
loki-package: ## Package Loki chart
	@$(PUSH_CHART) --chart $(LOKI_CHART_PATH) --package-only

.PHONY: loki-push
loki-push: ## Push Loki chart to OCI registry (REGISTRY=local)
	@$(PUSH_CHART) --chart $(LOKI_CHART_PATH) --registry $(REGISTRY)

.PHONY: tempo-package
tempo-package: ## Package Tempo chart
	@$(PUSH_CHART) --chart $(TEMPO_CHART_PATH) --package-only

.PHONY: tempo-push
tempo-push: ## Push Tempo chart to OCI registry (REGISTRY=local)
	@$(PUSH_CHART) --chart $(TEMPO_CHART_PATH) --registry $(REGISTRY)

.PHONY: mimir-package
mimir-package: ## Package Mimir chart
	@$(PUSH_CHART) --chart $(MIMIR_CHART_PATH) --package-only

.PHONY: mimir-push
mimir-push: ## Push Mimir chart to OCI registry (REGISTRY=local)
	@$(PUSH_CHART) --chart $(MIMIR_CHART_PATH) --registry $(REGISTRY)

.PHONY: grafana-push-all
grafana-push-all: grafana-push loki-push tempo-push mimir-push ## Push all Grafana stack charts to OCI registry

# =============================================================================
# MIRRORING (UPSTREAM → OCI REGISTRY)
# =============================================================================

.PHONY: grafana-mirror
grafana-mirror: ## Mirror Grafana chart + images to DOCR (VERSION=<ver>)
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart grafana $(if $(VERSION),--version $(VERSION))

.PHONY: grafana-images
grafana-images: ## List container images in Grafana chart
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart grafana --dry-run --images-only -o json | jq -r '.charts[].versions[].images[].source'

.PHONY: loki-mirror
loki-mirror: ## Mirror Loki chart + images to DOCR (VERSION=<ver>)
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart loki $(if $(VERSION),--version $(VERSION))

.PHONY: loki-images
loki-images: ## List container images in Loki chart
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart loki --dry-run --images-only -o json | jq -r '.charts[].versions[].images[].source'

.PHONY: tempo-mirror
tempo-mirror: ## Mirror Tempo chart + images to DOCR (VERSION=<ver>)
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart tempo $(if $(VERSION),--version $(VERSION))

.PHONY: tempo-images
tempo-images: ## List container images in Tempo chart
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart tempo --dry-run --images-only -o json | jq -r '.charts[].versions[].images[].source'

.PHONY: mimir-mirror
mimir-mirror: ## Mirror Mimir chart + images to DOCR (VERSION=<ver>)
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart mimir-distributed $(if $(VERSION),--version $(VERSION))

.PHONY: mimir-images
mimir-images: ## List container images in Mimir chart
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart mimir-distributed --dry-run --images-only -o json | jq -r '.charts[].versions[].images[].source'

.PHONY: grafana-mirror-all
grafana-mirror-all: grafana-mirror loki-mirror tempo-mirror mimir-mirror ## Mirror all Grafana stack charts
