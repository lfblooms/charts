# Prometheus Community Helm Charts Makefile
# Fork: MisterGrinvalds/prometheus-community.helm-charts
# Upstream: prometheus-community/helm-charts
# Charts: prometheus, kube-prometheus-stack

PROMETHEUS_FORK_PATH := forks/prometheus-helm-charts/charts

# Prometheus (standalone)
PROMETHEUS_CHART_PATH := $(PROMETHEUS_FORK_PATH)/prometheus
PROMETHEUS_RELEASE := prometheus
PROMETHEUS_NAMESPACE := monitoring
PROMETHEUS_VALUES_BASE := configs/values/prometheus/base.yaml
PROMETHEUS_VALUES_CTX := configs/values/prometheus/$(CONTEXT).yaml

# Kube Prometheus Stack (full stack with Grafana, Alertmanager, etc.)
KUBEPROMSTACK_CHART_PATH := $(PROMETHEUS_FORK_PATH)/kube-prometheus-stack
KUBEPROMSTACK_RELEASE := kube-prometheus-stack
KUBEPROMSTACK_NAMESPACE := monitoring
KUBEPROMSTACK_VALUES_BASE := configs/values/kube-prometheus-stack/base.yaml
KUBEPROMSTACK_VALUES_CTX := configs/values/kube-prometheus-stack/$(CONTEXT).yaml

# =============================================================================
# PROMETHEUS TARGETS
# =============================================================================

.PHONY: prometheus-lint
prometheus-lint: ## Lint Prometheus chart
	@echo "$(GREEN)Linting Prometheus chart...$(NC)"
	@$(HELM) lint $(PROMETHEUS_CHART_PATH)

.PHONY: prometheus-template
prometheus-template: ## Render Prometheus templates
	@echo "$(GREEN)Rendering Prometheus templates...$(NC)"
	@$(HELM) template $(PROMETHEUS_RELEASE) $(PROMETHEUS_CHART_PATH) \
		$(if $(wildcard $(PROMETHEUS_VALUES_BASE)),-f $(PROMETHEUS_VALUES_BASE)) \
		$(if $(wildcard $(PROMETHEUS_VALUES_CTX)),-f $(PROMETHEUS_VALUES_CTX))

.PHONY: prometheus-deps
prometheus-deps: ## Update Prometheus chart dependencies
	@echo "$(GREEN)Updating Prometheus dependencies...$(NC)"
	@$(HELM) dependency update $(PROMETHEUS_CHART_PATH)

.PHONY: prometheus-install
prometheus-install: ## Install Prometheus
	@echo "$(GREEN)Installing Prometheus...$(NC)"
	@$(KUBECTL) create namespace $(PROMETHEUS_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(PROMETHEUS_RELEASE) $(PROMETHEUS_CHART_PATH) \
		--namespace $(PROMETHEUS_NAMESPACE) \
		$(if $(wildcard $(PROMETHEUS_VALUES_BASE)),-f $(PROMETHEUS_VALUES_BASE)) \
		$(if $(wildcard $(PROMETHEUS_VALUES_CTX)),-f $(PROMETHEUS_VALUES_CTX)) \
		--wait

.PHONY: prometheus-upgrade
prometheus-upgrade: ## Upgrade Prometheus
	@echo "$(GREEN)Upgrading Prometheus...$(NC)"
	@$(HELM) upgrade $(PROMETHEUS_RELEASE) $(PROMETHEUS_CHART_PATH) \
		--namespace $(PROMETHEUS_NAMESPACE) \
		$(if $(wildcard $(PROMETHEUS_VALUES_BASE)),-f $(PROMETHEUS_VALUES_BASE)) \
		$(if $(wildcard $(PROMETHEUS_VALUES_CTX)),-f $(PROMETHEUS_VALUES_CTX)) \
		--wait

.PHONY: prometheus-uninstall
prometheus-uninstall: ## Uninstall Prometheus
	@echo "$(RED)Uninstalling Prometheus...$(NC)"
	@$(HELM) uninstall $(PROMETHEUS_RELEASE) --namespace $(PROMETHEUS_NAMESPACE) || true

.PHONY: prometheus-status
prometheus-status: ## Show Prometheus status
	@echo "$(GREEN)Prometheus Status:$(NC)"
	@$(HELM) status $(PROMETHEUS_RELEASE) --namespace $(PROMETHEUS_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(PROMETHEUS_NAMESPACE) -l app.kubernetes.io/name=prometheus 2>/dev/null || true

.PHONY: prometheus-logs
prometheus-logs: ## View Prometheus logs
	@$(KUBECTL) logs -n $(PROMETHEUS_NAMESPACE) -l app.kubernetes.io/name=prometheus -f --tail=100

.PHONY: prometheus-port-forward
prometheus-port-forward: ## Port forward Prometheus UI (localhost:9090)
	@echo "$(GREEN)Prometheus UI available at http://localhost:9090$(NC)"
	@$(KUBECTL) port-forward svc/$(PROMETHEUS_RELEASE)-server -n $(PROMETHEUS_NAMESPACE) 9090:80

# =============================================================================
# KUBE-PROMETHEUS-STACK TARGETS
# =============================================================================

.PHONY: kube-prometheus-stack-lint
kube-prometheus-stack-lint: ## Lint kube-prometheus-stack chart
	@echo "$(GREEN)Linting kube-prometheus-stack chart...$(NC)"
	@$(HELM) lint $(KUBEPROMSTACK_CHART_PATH)

.PHONY: kube-prometheus-stack-template
kube-prometheus-stack-template: ## Render kube-prometheus-stack templates
	@echo "$(GREEN)Rendering kube-prometheus-stack templates...$(NC)"
	@$(HELM) template $(KUBEPROMSTACK_RELEASE) $(KUBEPROMSTACK_CHART_PATH) \
		$(if $(wildcard $(KUBEPROMSTACK_VALUES_BASE)),-f $(KUBEPROMSTACK_VALUES_BASE)) \
		$(if $(wildcard $(KUBEPROMSTACK_VALUES_CTX)),-f $(KUBEPROMSTACK_VALUES_CTX))

.PHONY: kube-prometheus-stack-deps
kube-prometheus-stack-deps: ## Update kube-prometheus-stack chart dependencies
	@echo "$(GREEN)Updating kube-prometheus-stack dependencies...$(NC)"
	@$(HELM) dependency update $(KUBEPROMSTACK_CHART_PATH)

.PHONY: kube-prometheus-stack-install
kube-prometheus-stack-install: kube-prometheus-stack-deps ## Install kube-prometheus-stack
	@echo "$(GREEN)Installing kube-prometheus-stack...$(NC)"
	@$(KUBECTL) create namespace $(KUBEPROMSTACK_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(KUBEPROMSTACK_RELEASE) $(KUBEPROMSTACK_CHART_PATH) \
		--namespace $(KUBEPROMSTACK_NAMESPACE) \
		$(if $(wildcard $(KUBEPROMSTACK_VALUES_BASE)),-f $(KUBEPROMSTACK_VALUES_BASE)) \
		$(if $(wildcard $(KUBEPROMSTACK_VALUES_CTX)),-f $(KUBEPROMSTACK_VALUES_CTX)) \
		--wait --timeout 10m

.PHONY: kube-prometheus-stack-upgrade
kube-prometheus-stack-upgrade: kube-prometheus-stack-deps ## Upgrade kube-prometheus-stack
	@echo "$(GREEN)Upgrading kube-prometheus-stack...$(NC)"
	@$(HELM) upgrade $(KUBEPROMSTACK_RELEASE) $(KUBEPROMSTACK_CHART_PATH) \
		--namespace $(KUBEPROMSTACK_NAMESPACE) \
		$(if $(wildcard $(KUBEPROMSTACK_VALUES_BASE)),-f $(KUBEPROMSTACK_VALUES_BASE)) \
		$(if $(wildcard $(KUBEPROMSTACK_VALUES_CTX)),-f $(KUBEPROMSTACK_VALUES_CTX)) \
		--wait --timeout 10m

.PHONY: kube-prometheus-stack-uninstall
kube-prometheus-stack-uninstall: ## Uninstall kube-prometheus-stack
	@echo "$(RED)Uninstalling kube-prometheus-stack...$(NC)"
	@$(HELM) uninstall $(KUBEPROMSTACK_RELEASE) --namespace $(KUBEPROMSTACK_NAMESPACE) || true

.PHONY: kube-prometheus-stack-status
kube-prometheus-stack-status: ## Show kube-prometheus-stack status
	@echo "$(GREEN)kube-prometheus-stack Status:$(NC)"
	@$(HELM) status $(KUBEPROMSTACK_RELEASE) --namespace $(KUBEPROMSTACK_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(KUBEPROMSTACK_NAMESPACE) 2>/dev/null || true

.PHONY: prometheus-sync
prometheus-sync: ## Sync fork with upstream
	@echo "$(GREEN)Syncing Prometheus helm-charts fork with upstream...$(NC)"
	@cd forks/prometheus-helm-charts && git fetch upstream && git merge upstream/main --no-edit
