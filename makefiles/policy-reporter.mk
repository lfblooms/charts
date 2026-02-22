# Policy Reporter Helm Chart Makefile
# Fork: lfblooms/kyverno.policy-reporter
# Upstream: kyverno/policy-reporter

POLICYREPORTER_CHART_PATH := forks/policy-reporter/charts/policy-reporter
POLICYREPORTER_RELEASE := policy-reporter
POLICYREPORTER_NAMESPACE := policy-reporter
POLICYREPORTER_VALUES_BASE := configs/values/policy-reporter/base.yaml
POLICYREPORTER_VALUES_CTX := configs/values/policy-reporter/$(CONTEXT).yaml

# =============================================================================
# POLICY-REPORTER TARGETS
# =============================================================================

.PHONY: policy-reporter-lint
policy-reporter-lint: ## Lint Policy Reporter chart
	@echo "$(GREEN)Linting Policy Reporter chart...$(NC)"
	@$(HELM) lint $(POLICYREPORTER_CHART_PATH)

.PHONY: policy-reporter-template
policy-reporter-template: ## Render Policy Reporter templates
	@echo "$(GREEN)Rendering Policy Reporter templates...$(NC)"
	@$(HELM) template $(POLICYREPORTER_RELEASE) $(POLICYREPORTER_CHART_PATH) \
		$(if $(wildcard $(POLICYREPORTER_VALUES_BASE)),-f $(POLICYREPORTER_VALUES_BASE)) \
		$(if $(wildcard $(POLICYREPORTER_VALUES_CTX)),-f $(POLICYREPORTER_VALUES_CTX))

.PHONY: policy-reporter-deps
policy-reporter-deps: ## Update Policy Reporter chart dependencies
	@echo "$(GREEN)Updating Policy Reporter dependencies...$(NC)"
	@$(HELM) dependency update $(POLICYREPORTER_CHART_PATH)

.PHONY: policy-reporter-install
policy-reporter-install: ## Install Policy Reporter
	@echo "$(GREEN)Installing Policy Reporter...$(NC)"
	@$(KUBECTL) create namespace $(POLICYREPORTER_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(POLICYREPORTER_RELEASE) $(POLICYREPORTER_CHART_PATH) \
		--namespace $(POLICYREPORTER_NAMESPACE) \
		$(if $(wildcard $(POLICYREPORTER_VALUES_BASE)),-f $(POLICYREPORTER_VALUES_BASE)) \
		$(if $(wildcard $(POLICYREPORTER_VALUES_CTX)),-f $(POLICYREPORTER_VALUES_CTX)) \
		--wait

.PHONY: policy-reporter-upgrade
policy-reporter-upgrade: ## Upgrade Policy Reporter
	@echo "$(GREEN)Upgrading Policy Reporter...$(NC)"
	@$(HELM) upgrade $(POLICYREPORTER_RELEASE) $(POLICYREPORTER_CHART_PATH) \
		--namespace $(POLICYREPORTER_NAMESPACE) \
		$(if $(wildcard $(POLICYREPORTER_VALUES_BASE)),-f $(POLICYREPORTER_VALUES_BASE)) \
		$(if $(wildcard $(POLICYREPORTER_VALUES_CTX)),-f $(POLICYREPORTER_VALUES_CTX)) \
		--wait

.PHONY: policy-reporter-uninstall
policy-reporter-uninstall: ## Uninstall Policy Reporter
	@echo "$(RED)Uninstalling Policy Reporter...$(NC)"
	@$(HELM) uninstall $(POLICYREPORTER_RELEASE) --namespace $(POLICYREPORTER_NAMESPACE) || true

.PHONY: policy-reporter-status
policy-reporter-status: ## Show Policy Reporter status
	@echo "$(GREEN)Policy Reporter Status:$(NC)"
	@$(HELM) status $(POLICYREPORTER_RELEASE) --namespace $(POLICYREPORTER_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(POLICYREPORTER_NAMESPACE) 2>/dev/null || true

.PHONY: policy-reporter-logs
policy-reporter-logs: ## View Policy Reporter logs
	@$(KUBECTL) logs -n $(POLICYREPORTER_NAMESPACE) -l app.kubernetes.io/name=policy-reporter -f --tail=100

.PHONY: policy-reporter-port-forward
policy-reporter-port-forward: ## Port forward Policy Reporter UI (localhost:8082)
	@echo "$(GREEN)Policy Reporter UI available at http://localhost:8082$(NC)"
	@$(KUBECTL) port-forward svc/$(POLICYREPORTER_RELEASE)-ui -n $(POLICYREPORTER_NAMESPACE) 8082:8080

.PHONY: policy-reporter-sync
policy-reporter-sync: ## Sync fork with upstream
	@echo "$(GREEN)Syncing Policy Reporter fork with upstream...$(NC)"
	@cd forks/policy-reporter && git fetch upstream && git merge upstream/main --no-edit

# =============================================================================
# OCI PACKAGING & PUBLISHING
# =============================================================================

.PHONY: policy-reporter-package
policy-reporter-package: ## Package Policy Reporter chart
	@$(PUSH_CHART) --chart $(POLICYREPORTER_CHART_PATH) --package-only

.PHONY: policy-reporter-push
policy-reporter-push: ## Push Policy Reporter chart to OCI registry (REGISTRY=local)
	@$(PUSH_CHART) --chart $(POLICYREPORTER_CHART_PATH) --registry $(REGISTRY)

# =============================================================================
# MIRRORING (UPSTREAM → OCI REGISTRY)
# =============================================================================

.PHONY: policy-reporter-mirror
policy-reporter-mirror: ## Mirror Policy Reporter chart + images (MIRROR_REGISTRY=docr, SINCE=<ver>)
	@$(MIRROR_CHART) --chart policy-reporter $(if $(SINCE),--since $(SINCE)) --registry $(MIRROR_REGISTRY)

.PHONY: policy-reporter-images
policy-reporter-images: ## List container images in Policy Reporter chart
	@$(EXTRACT_IMAGES) $(POLICYREPORTER_CHART_PATH)
