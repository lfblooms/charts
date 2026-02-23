# external-dns Helm Chart Makefile
# Fork: lfblooms/kubernetes-sigs.external-dns
# Upstream: kubernetes-sigs/external-dns

EXTERNALDNS_CHART_PATH := forks/external-dns/charts/external-dns
EXTERNALDNS_RELEASE := external-dns
EXTERNALDNS_NAMESPACE := external-dns
EXTERNALDNS_VALUES_BASE := configs/values/external-dns/base.yaml
EXTERNALDNS_VALUES_CTX := configs/values/external-dns/$(CONTEXT).yaml

# =============================================================================
# EXTERNAL-DNS TARGETS
# =============================================================================

.PHONY: external-dns-lint
external-dns-lint: ## Lint external-dns chart
	@echo "$(GREEN)Linting external-dns chart...$(NC)"
	@$(HELM) lint $(EXTERNALDNS_CHART_PATH)

.PHONY: external-dns-template
external-dns-template: ## Render external-dns templates
	@echo "$(GREEN)Rendering external-dns templates...$(NC)"
	@$(HELM) template $(EXTERNALDNS_RELEASE) $(EXTERNALDNS_CHART_PATH) \
		$(if $(wildcard $(EXTERNALDNS_VALUES_BASE)),-f $(EXTERNALDNS_VALUES_BASE)) \
		$(if $(wildcard $(EXTERNALDNS_VALUES_CTX)),-f $(EXTERNALDNS_VALUES_CTX))

.PHONY: external-dns-deps
external-dns-deps: ## Update external-dns chart dependencies
	@echo "$(GREEN)Updating external-dns dependencies...$(NC)"
	@$(HELM) dependency update $(EXTERNALDNS_CHART_PATH)

.PHONY: external-dns-install
external-dns-install: ## Install external-dns
	@echo "$(GREEN)Installing external-dns...$(NC)"
	@$(KUBECTL) create namespace $(EXTERNALDNS_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(EXTERNALDNS_RELEASE) $(EXTERNALDNS_CHART_PATH) \
		--namespace $(EXTERNALDNS_NAMESPACE) \
		$(if $(wildcard $(EXTERNALDNS_VALUES_BASE)),-f $(EXTERNALDNS_VALUES_BASE)) \
		$(if $(wildcard $(EXTERNALDNS_VALUES_CTX)),-f $(EXTERNALDNS_VALUES_CTX)) \
		--wait

.PHONY: external-dns-upgrade
external-dns-upgrade: ## Upgrade external-dns
	@echo "$(GREEN)Upgrading external-dns...$(NC)"
	@$(HELM) upgrade $(EXTERNALDNS_RELEASE) $(EXTERNALDNS_CHART_PATH) \
		--namespace $(EXTERNALDNS_NAMESPACE) \
		$(if $(wildcard $(EXTERNALDNS_VALUES_BASE)),-f $(EXTERNALDNS_VALUES_BASE)) \
		$(if $(wildcard $(EXTERNALDNS_VALUES_CTX)),-f $(EXTERNALDNS_VALUES_CTX)) \
		--wait

.PHONY: external-dns-uninstall
external-dns-uninstall: ## Uninstall external-dns
	@echo "$(RED)Uninstalling external-dns...$(NC)"
	@$(HELM) uninstall $(EXTERNALDNS_RELEASE) --namespace $(EXTERNALDNS_NAMESPACE) || true

.PHONY: external-dns-status
external-dns-status: ## Show external-dns status
	@echo "$(GREEN)external-dns Status:$(NC)"
	@$(HELM) status $(EXTERNALDNS_RELEASE) --namespace $(EXTERNALDNS_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(EXTERNALDNS_NAMESPACE) 2>/dev/null || true

.PHONY: external-dns-logs
external-dns-logs: ## View external-dns logs
	@$(KUBECTL) logs -n $(EXTERNALDNS_NAMESPACE) -l app.kubernetes.io/name=external-dns -f --tail=100

.PHONY: external-dns-sync
external-dns-sync: ## Sync fork with upstream
	@echo "$(GREEN)Syncing external-dns fork with upstream...$(NC)"
	@cd forks/external-dns && git fetch upstream && git merge upstream/master --no-edit

# =============================================================================
# OCI PACKAGING & PUBLISHING
# =============================================================================

.PHONY: external-dns-package
external-dns-package: ## Package external-dns chart
	@$(PUSH_CHART) --chart $(EXTERNALDNS_CHART_PATH) --package-only

.PHONY: external-dns-push
external-dns-push: ## Push external-dns chart to OCI registry (REGISTRY=local)
	@$(PUSH_CHART) --chart $(EXTERNALDNS_CHART_PATH) --registry $(REGISTRY)

# =============================================================================
# MIRRORING (UPSTREAM → OCI REGISTRY)
# =============================================================================

.PHONY: external-dns-mirror
external-dns-mirror: ## Mirror external-dns chart + images to DOCR (VERSION=<ver>)
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart external-dns $(if $(VERSION),--version $(VERSION))

.PHONY: external-dns-images
external-dns-images: ## List container images in external-dns chart
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart external-dns --dry-run --images-only -o json | jq -r '.charts[].versions[].images[].source'
