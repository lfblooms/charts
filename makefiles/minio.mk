# MinIO Helm Chart Makefile
# Fork: MisterGrinvalds/minio.minio
# Upstream: minio/minio

MINIO_CHART_PATH := forks/minio/helm/minio
MINIO_RELEASE := minio
MINIO_NAMESPACE := minio
MINIO_VALUES_BASE := configs/values/minio/base.yaml
MINIO_VALUES_CTX := configs/values/minio/$(CONTEXT).yaml

# =============================================================================
# MINIO TARGETS
# =============================================================================

.PHONY: minio-lint
minio-lint: ## Lint MinIO chart
	@echo "$(GREEN)Linting MinIO chart...$(NC)"
	@$(HELM) lint $(MINIO_CHART_PATH)

.PHONY: minio-template
minio-template: ## Render MinIO templates
	@echo "$(GREEN)Rendering MinIO templates...$(NC)"
	@$(HELM) template $(MINIO_RELEASE) $(MINIO_CHART_PATH) \
		$(if $(wildcard $(MINIO_VALUES_BASE)),-f $(MINIO_VALUES_BASE)) \
		$(if $(wildcard $(MINIO_VALUES_CTX)),-f $(MINIO_VALUES_CTX))

.PHONY: minio-deps
minio-deps: ## Update MinIO chart dependencies
	@echo "$(GREEN)Updating MinIO dependencies...$(NC)"
	@$(HELM) dependency update $(MINIO_CHART_PATH)

.PHONY: minio-install
minio-install: ## Install MinIO
	@echo "$(GREEN)Installing MinIO...$(NC)"
	@$(KUBECTL) create namespace $(MINIO_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(MINIO_RELEASE) $(MINIO_CHART_PATH) \
		--namespace $(MINIO_NAMESPACE) \
		$(if $(wildcard $(MINIO_VALUES_BASE)),-f $(MINIO_VALUES_BASE)) \
		$(if $(wildcard $(MINIO_VALUES_CTX)),-f $(MINIO_VALUES_CTX)) \
		--wait

.PHONY: minio-upgrade
minio-upgrade: ## Upgrade MinIO
	@echo "$(GREEN)Upgrading MinIO...$(NC)"
	@$(HELM) upgrade $(MINIO_RELEASE) $(MINIO_CHART_PATH) \
		--namespace $(MINIO_NAMESPACE) \
		$(if $(wildcard $(MINIO_VALUES_BASE)),-f $(MINIO_VALUES_BASE)) \
		$(if $(wildcard $(MINIO_VALUES_CTX)),-f $(MINIO_VALUES_CTX)) \
		--wait

.PHONY: minio-uninstall
minio-uninstall: ## Uninstall MinIO
	@echo "$(RED)Uninstalling MinIO...$(NC)"
	@$(HELM) uninstall $(MINIO_RELEASE) --namespace $(MINIO_NAMESPACE) || true

.PHONY: minio-status
minio-status: ## Show MinIO status
	@echo "$(GREEN)MinIO Status:$(NC)"
	@$(HELM) status $(MINIO_RELEASE) --namespace $(MINIO_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(MINIO_NAMESPACE) 2>/dev/null || true

.PHONY: minio-logs
minio-logs: ## View MinIO logs
	@$(KUBECTL) logs -n $(MINIO_NAMESPACE) -l app=minio -f --tail=100

.PHONY: minio-port-forward
minio-port-forward: ## Port forward MinIO console (localhost:9001)
	@echo "$(GREEN)MinIO Console available at http://localhost:9001$(NC)"
	@$(KUBECTL) port-forward svc/$(MINIO_RELEASE)-console -n $(MINIO_NAMESPACE) 9001:9001

.PHONY: minio-api-port-forward
minio-api-port-forward: ## Port forward MinIO API (localhost:9000)
	@echo "$(GREEN)MinIO API available at http://localhost:9000$(NC)"
	@$(KUBECTL) port-forward svc/$(MINIO_RELEASE) -n $(MINIO_NAMESPACE) 9000:9000

.PHONY: minio-credentials
minio-credentials: ## Get MinIO access credentials
	@echo "$(GREEN)MinIO Credentials:$(NC)"
	@echo "Root User: $$($(KUBECTL) get secret -n $(MINIO_NAMESPACE) $(MINIO_RELEASE) -o jsonpath='{.data.rootUser}' | base64 -d)"
	@echo "Root Password: $$($(KUBECTL) get secret -n $(MINIO_NAMESPACE) $(MINIO_RELEASE) -o jsonpath='{.data.rootPassword}' | base64 -d)"

.PHONY: minio-sync
minio-sync: ## Sync fork with upstream
	@echo "$(GREEN)Syncing MinIO fork with upstream...$(NC)"
	@cd forks/minio && git fetch upstream && git merge upstream/master --no-edit
