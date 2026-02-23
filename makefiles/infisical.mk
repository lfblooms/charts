# Infisical Chart Makefile
# Targets for managing Infisical Helm chart

# Chart configuration
INFISICAL_CHART := forks/infisical/helm-charts/infisical-standalone-postgres
INFISICAL_RELEASE := infisical
INFISICAL_NAMESPACE := infisical
INFISICAL_VALUES_BASE := configs/values/infisical/base.yaml
INFISICAL_VALUES_LOCAL := configs/values/infisical/local.yaml

# =============================================================================
# INFISICAL TARGETS
# =============================================================================

.PHONY: infisical-ns
infisical-ns: ## Create infisical namespace
	@echo "$(GREEN)Creating namespace '$(INFISICAL_NAMESPACE)'...$(NC)"
	@$(KUBECTL) create namespace $(INFISICAL_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -

.PHONY: infisical-secrets
infisical-secrets: infisical-ns ## Create infisical secrets (dev only)
	@echo "$(GREEN)Creating infisical-secrets...$(NC)"
	@$(KUBECTL) create secret generic infisical-secrets \
		--from-literal=ENCRYPTION_KEY=$$(openssl rand -hex 16) \
		--from-literal=AUTH_SECRET=$$(openssl rand -base64 32 | tr -d '\n') \
		--from-literal=SITE_URL=http://localhost:8080 \
		--namespace $(INFISICAL_NAMESPACE) \
		--dry-run=client -o yaml | $(KUBECTL) apply -f -

.PHONY: infisical-deps
infisical-deps: ## Update infisical chart dependencies
	@echo "$(GREEN)Updating chart dependencies...$(NC)"
	@$(HELM) dependency update $(INFISICAL_CHART)

.PHONY: infisical-lint
infisical-lint: ## Lint infisical chart
	@echo "$(GREEN)Linting chart...$(NC)"
	@$(HELM) lint $(INFISICAL_CHART)

.PHONY: infisical-template
infisical-template: ## Render infisical templates locally
	@echo "$(GREEN)Rendering templates...$(NC)"
	@$(HELM) template $(INFISICAL_RELEASE) $(INFISICAL_CHART) \
		-f $(INFISICAL_VALUES_BASE) \
		--namespace $(INFISICAL_NAMESPACE)

.PHONY: infisical-dry-run
infisical-dry-run: infisical-ns infisical-secrets ## Dry-run infisical installation
	@echo "$(GREEN)Dry-run installation...$(NC)"
	@$(HELM) install $(INFISICAL_RELEASE) $(INFISICAL_CHART) \
		-f $(INFISICAL_VALUES_BASE) \
		--namespace $(INFISICAL_NAMESPACE) \
		--dry-run

.PHONY: infisical-install
infisical-install: infisical-ns infisical-secrets infisical-deps ## Install infisical chart
	@echo "$(GREEN)Installing infisical...$(NC)"
	@$(HELM) upgrade --install $(INFISICAL_RELEASE) $(INFISICAL_CHART) \
		-f $(INFISICAL_VALUES_BASE) \
		--namespace $(INFISICAL_NAMESPACE) \
		--wait --timeout 5m
	@echo ""
	@echo "$(GREEN)Installation complete!$(NC)"
	@echo "Run 'make infisical-status' to check pod status"
	@echo "Run 'make infisical-port-forward' to access the UI"

.PHONY: infisical-upgrade
infisical-upgrade: ## Upgrade infisical release
	@echo "$(GREEN)Upgrading infisical...$(NC)"
	@$(HELM) upgrade $(INFISICAL_RELEASE) $(INFISICAL_CHART) \
		-f $(INFISICAL_VALUES_BASE) \
		--namespace $(INFISICAL_NAMESPACE) \
		--wait --timeout 5m

.PHONY: infisical-uninstall
infisical-uninstall: ## Uninstall infisical chart
	@echo "$(YELLOW)Uninstalling infisical...$(NC)"
	@$(HELM) uninstall $(INFISICAL_RELEASE) --namespace $(INFISICAL_NAMESPACE) || true
	@echo "$(YELLOW)Deleting PVCs...$(NC)"
	@$(KUBECTL) delete pvc -l app.kubernetes.io/instance=$(INFISICAL_RELEASE) -n $(INFISICAL_NAMESPACE) --ignore-not-found
	@echo "$(GREEN)Uninstall complete$(NC)"

.PHONY: infisical-purge
infisical-purge: infisical-uninstall ## Completely remove infisical including namespace
	@echo "$(RED)Deleting namespace '$(INFISICAL_NAMESPACE)'...$(NC)"
	@$(KUBECTL) delete namespace $(INFISICAL_NAMESPACE) --ignore-not-found
	@echo "$(GREEN)Purge complete$(NC)"

.PHONY: infisical-status
infisical-status: ## Show infisical deployment status
	@echo "$(GREEN)Helm Release:$(NC)"
	@$(HELM) status $(INFISICAL_RELEASE) -n $(INFISICAL_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@echo "$(GREEN)Pods:$(NC)"
	@$(KUBECTL) get pods -n $(INFISICAL_NAMESPACE) -l app.kubernetes.io/instance=$(INFISICAL_RELEASE) 2>/dev/null || echo "No pods found"
	@echo ""
	@echo "$(GREEN)Services:$(NC)"
	@$(KUBECTL) get svc -n $(INFISICAL_NAMESPACE) 2>/dev/null || echo "No services found"
	@echo ""
	@echo "$(GREEN)PVCs:$(NC)"
	@$(KUBECTL) get pvc -n $(INFISICAL_NAMESPACE) 2>/dev/null || echo "No PVCs found"

.PHONY: infisical-logs
infisical-logs: ## Show infisical pod logs
	@$(KUBECTL) logs -l app.kubernetes.io/name=infisical -n $(INFISICAL_NAMESPACE) -f --tail=100

.PHONY: infisical-logs-postgres
infisical-logs-postgres: ## Show PostgreSQL pod logs
	@$(KUBECTL) logs -l app.kubernetes.io/name=postgresql -n $(INFISICAL_NAMESPACE) -f --tail=100

.PHONY: infisical-logs-redis
infisical-logs-redis: ## Show Redis pod logs
	@$(KUBECTL) logs -l app.kubernetes.io/name=redis -n $(INFISICAL_NAMESPACE) -f --tail=100

.PHONY: infisical-port-forward
infisical-port-forward: ## Port forward infisical to localhost:8080
	@echo "$(GREEN)Forwarding infisical to http://localhost:8080$(NC)"
	@echo "Press Ctrl+C to stop"
	@$(KUBECTL) port-forward svc/$(INFISICAL_RELEASE) 8080:80 -n $(INFISICAL_NAMESPACE)

.PHONY: infisical-shell
infisical-shell: ## Open shell in infisical pod
	@$(KUBECTL) exec -it deploy/$(INFISICAL_RELEASE) -n $(INFISICAL_NAMESPACE) -- /bin/sh

.PHONY: infisical-test
infisical-test: ## Run Helm tests for infisical
	@echo "$(GREEN)Running Helm tests...$(NC)"
	@$(HELM) test $(INFISICAL_RELEASE) -n $(INFISICAL_NAMESPACE)

.PHONY: infisical-events
infisical-events: ## Show events in infisical namespace
	@$(KUBECTL) get events -n $(INFISICAL_NAMESPACE) --sort-by='.lastTimestamp'

.PHONY: infisical-describe
infisical-describe: ## Describe infisical pods
	@$(KUBECTL) describe pods -l app.kubernetes.io/name=infisical -n $(INFISICAL_NAMESPACE)

.PHONY: infisical-restart
infisical-restart: ## Restart infisical pods
	@echo "$(YELLOW)Restarting infisical pods...$(NC)"
	@$(KUBECTL) rollout restart deployment/$(INFISICAL_RELEASE) -n $(INFISICAL_NAMESPACE)
	@$(KUBECTL) rollout status deployment/$(INFISICAL_RELEASE) -n $(INFISICAL_NAMESPACE)

.PHONY: infisical-wait
infisical-wait: ## Wait for infisical pods to be ready
	@echo "$(GREEN)Waiting for pods to be ready...$(NC)"
	@$(KUBECTL) wait --for=condition=ready pod -l app.kubernetes.io/name=infisical -n $(INFISICAL_NAMESPACE) --timeout=300s

# =============================================================================
# OCI PACKAGING & PUBLISHING
# =============================================================================

.PHONY: infisical-package
infisical-package: ## Package infisical chart
	@$(PUSH_CHART) --chart $(INFISICAL_CHART) --package-only

.PHONY: infisical-push
infisical-push: ## Push infisical chart to OCI registry (REGISTRY=local)
	@$(PUSH_CHART) --chart $(INFISICAL_CHART) --registry $(REGISTRY)

# =============================================================================
# MIRRORING (UPSTREAM → OCI REGISTRY)
# =============================================================================

.PHONY: infisical-mirror
infisical-mirror: ## Mirror Infisical chart + images to DOCR (VERSION=<ver>)
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart infisical $(if $(VERSION),--version $(VERSION))

.PHONY: infisical-images
infisical-images: ## List container images in Infisical chart
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart infisical --dry-run --images-only -o json | jq -r '.charts[].versions[].images[].source'

.PHONY: infisical-gateway-mirror
infisical-gateway-mirror: ## Mirror Infisical Gateway chart + images to DOCR (VERSION=<ver>)
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart infisical-gateway $(if $(VERSION),--version $(VERSION))

.PHONY: infisical-gateway-images
infisical-gateway-images: ## List container images in Infisical Gateway chart
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart infisical-gateway --dry-run --images-only -o json | jq -r '.charts[].versions[].images[].source'
