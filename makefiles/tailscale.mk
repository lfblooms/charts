# Tailscale Operator Chart Makefile
# Targets for managing Tailscale Kubernetes operator Helm chart

# Chart configuration
TAILSCALE_CHART := forks/tailscale/cmd/k8s-operator/deploy/chart
TAILSCALE_RELEASE := tailscale-operator
TAILSCALE_NAMESPACE := tailscale
TAILSCALE_VALUES_BASE := configs/values/tailscale-operator/base.yaml
TAILSCALE_VALUES_LOCAL := configs/values/tailscale-operator/local.yaml

# =============================================================================
# TAILSCALE TARGETS
# =============================================================================

.PHONY: tailscale-ns
tailscale-ns: ## Create tailscale namespace
	@echo "$(GREEN)Creating namespace '$(TAILSCALE_NAMESPACE)'...$(NC)"
	@$(KUBECTL) create namespace $(TAILSCALE_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -

.PHONY: tailscale-secrets
tailscale-secrets: tailscale-ns ## Create tailscale OAuth secret (requires TAILSCALE_CLIENT_ID and TAILSCALE_CLIENT_SECRET)
	@echo "$(GREEN)Creating tailscale-operator-oauth secret...$(NC)"
	@if [ -z "$(TAILSCALE_CLIENT_ID)" ] || [ -z "$(TAILSCALE_CLIENT_SECRET)" ]; then \
		echo "$(RED)Error: TAILSCALE_CLIENT_ID and TAILSCALE_CLIENT_SECRET must be set$(NC)"; \
		echo "Create OAuth credentials at: https://login.tailscale.com/admin/settings/oauth"; \
		exit 1; \
	fi
	@$(KUBECTL) create secret generic tailscale-operator-oauth \
		--from-literal=client_id=$(TAILSCALE_CLIENT_ID) \
		--from-literal=client_secret=$(TAILSCALE_CLIENT_SECRET) \
		--namespace $(TAILSCALE_NAMESPACE) \
		--dry-run=client -o yaml | $(KUBECTL) apply -f -

.PHONY: tailscale-lint
tailscale-lint: ## Lint tailscale chart
	@echo "$(GREEN)Linting chart...$(NC)"
	@$(HELM) lint $(TAILSCALE_CHART)

.PHONY: tailscale-template
tailscale-template: ## Render tailscale templates locally
	@echo "$(GREEN)Rendering templates...$(NC)"
	@$(HELM) template $(TAILSCALE_RELEASE) $(TAILSCALE_CHART) \
		-f $(TAILSCALE_VALUES_BASE) \
		--namespace $(TAILSCALE_NAMESPACE)

.PHONY: tailscale-dry-run
tailscale-dry-run: tailscale-ns ## Dry-run tailscale installation
	@echo "$(GREEN)Dry-run installation...$(NC)"
	@$(HELM) install $(TAILSCALE_RELEASE) $(TAILSCALE_CHART) \
		-f $(TAILSCALE_VALUES_BASE) \
		--namespace $(TAILSCALE_NAMESPACE) \
		--dry-run

.PHONY: tailscale-install
tailscale-install: tailscale-ns tailscale-secrets ## Install tailscale chart (requires OAuth credentials)
	@echo "$(GREEN)Installing tailscale-operator...$(NC)"
	@$(HELM) upgrade --install $(TAILSCALE_RELEASE) $(TAILSCALE_CHART) \
		-f $(TAILSCALE_VALUES_BASE) \
		--namespace $(TAILSCALE_NAMESPACE) \
		--wait --timeout 5m
	@echo ""
	@echo "$(GREEN)Installation complete!$(NC)"
	@echo "Run 'make tailscale-status' to check pod status"

.PHONY: tailscale-upgrade
tailscale-upgrade: ## Upgrade tailscale release
	@echo "$(GREEN)Upgrading tailscale-operator...$(NC)"
	@$(HELM) upgrade $(TAILSCALE_RELEASE) $(TAILSCALE_CHART) \
		-f $(TAILSCALE_VALUES_BASE) \
		--namespace $(TAILSCALE_NAMESPACE) \
		--wait --timeout 5m

.PHONY: tailscale-uninstall
tailscale-uninstall: ## Uninstall tailscale chart
	@echo "$(YELLOW)Uninstalling tailscale-operator...$(NC)"
	@$(HELM) uninstall $(TAILSCALE_RELEASE) --namespace $(TAILSCALE_NAMESPACE) || true
	@echo "$(GREEN)Uninstall complete$(NC)"

.PHONY: tailscale-purge
tailscale-purge: tailscale-uninstall ## Completely remove tailscale including namespace
	@echo "$(RED)Deleting namespace '$(TAILSCALE_NAMESPACE)'...$(NC)"
	@$(KUBECTL) delete namespace $(TAILSCALE_NAMESPACE) --ignore-not-found
	@echo "$(GREEN)Purge complete$(NC)"

.PHONY: tailscale-status
tailscale-status: ## Show tailscale deployment status
	@echo "$(GREEN)Helm Release:$(NC)"
	@$(HELM) status $(TAILSCALE_RELEASE) -n $(TAILSCALE_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@echo "$(GREEN)Pods:$(NC)"
	@$(KUBECTL) get pods -n $(TAILSCALE_NAMESPACE) 2>/dev/null || echo "No pods found"
	@echo ""
	@echo "$(GREEN)Services:$(NC)"
	@$(KUBECTL) get svc -n $(TAILSCALE_NAMESPACE) 2>/dev/null || echo "No services found"
	@echo ""
	@echo "$(GREEN)Tailscale Proxies:$(NC)"
	@$(KUBECTL) get pods -l app=tailscale -A 2>/dev/null || echo "No proxies found"

.PHONY: tailscale-logs
tailscale-logs: ## Show tailscale operator logs
	@$(KUBECTL) logs -l app.kubernetes.io/name=operator -n $(TAILSCALE_NAMESPACE) -f --tail=100

.PHONY: tailscale-events
tailscale-events: ## Show events in tailscale namespace
	@$(KUBECTL) get events -n $(TAILSCALE_NAMESPACE) --sort-by='.lastTimestamp'

.PHONY: tailscale-describe
tailscale-describe: ## Describe tailscale operator pods
	@$(KUBECTL) describe pods -l app.kubernetes.io/name=operator -n $(TAILSCALE_NAMESPACE)

.PHONY: tailscale-restart
tailscale-restart: ## Restart tailscale operator pods
	@echo "$(YELLOW)Restarting tailscale-operator pods...$(NC)"
	@$(KUBECTL) rollout restart deployment/$(TAILSCALE_RELEASE) -n $(TAILSCALE_NAMESPACE)
	@$(KUBECTL) rollout status deployment/$(TAILSCALE_RELEASE) -n $(TAILSCALE_NAMESPACE)

.PHONY: tailscale-crds
tailscale-crds: ## List Tailscale CRDs
	@echo "$(GREEN)Tailscale CRDs:$(NC)"
	@$(KUBECTL) get crds | grep tailscale || echo "No Tailscale CRDs found"

.PHONY: tailscale-connectors
tailscale-connectors: ## List Tailscale Connectors
	@echo "$(GREEN)Connectors:$(NC)"
	@$(KUBECTL) get connectors -A 2>/dev/null || echo "No connectors found"

.PHONY: tailscale-proxyclasses
tailscale-proxyclasses: ## List Tailscale ProxyClasses
	@echo "$(GREEN)ProxyClasses:$(NC)"
	@$(KUBECTL) get proxyclasses -A 2>/dev/null || echo "No proxy classes found"

# =============================================================================
# OCI PACKAGING & PUBLISHING
# =============================================================================

.PHONY: tailscale-package
tailscale-package: ## Package tailscale chart
	@$(PUSH_CHART) --chart $(TAILSCALE_CHART) --package-only

.PHONY: tailscale-push
tailscale-push: ## Push tailscale chart to OCI registry (REGISTRY=local)
	@$(PUSH_CHART) --chart $(TAILSCALE_CHART) --registry $(REGISTRY)

# =============================================================================
# MIRRORING (UPSTREAM → OCI REGISTRY)
# =============================================================================

.PHONY: tailscale-mirror
tailscale-mirror: ## Mirror Tailscale chart + images to DOCR (VERSION=<ver>)
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart tailscale-operator $(if $(VERSION),--version $(VERSION))

.PHONY: tailscale-images
tailscale-images: ## List container images in Tailscale chart
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart tailscale-operator --dry-run --images-only -o json | jq -r '.charts[].versions[].images[].source'
