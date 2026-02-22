# Istio Helm Charts Makefile
# Fork: lfblooms/istio.istio
# Upstream: istio/istio
# Charts: base, istiod, istio-cni, istio-ingress

ISTIO_FORK_PATH := forks/istio/manifests/charts

# Istio Base
ISTIO_BASE_CHART_PATH := $(ISTIO_FORK_PATH)/base
ISTIO_BASE_RELEASE := istio-base
ISTIO_BASE_NAMESPACE := istio-system
ISTIO_BASE_VALUES_BASE := configs/values/istio-base/base.yaml
ISTIO_BASE_VALUES_CTX := configs/values/istio-base/$(CONTEXT).yaml

# Istiod (Control Plane)
ISTIOD_CHART_PATH := $(ISTIO_FORK_PATH)/istio-control/istio-discovery
ISTIOD_RELEASE := istiod
ISTIOD_NAMESPACE := istio-system
ISTIOD_VALUES_BASE := configs/values/istiod/base.yaml
ISTIOD_VALUES_CTX := configs/values/istiod/$(CONTEXT).yaml

# Istio CNI
ISTIO_CNI_CHART_PATH := $(ISTIO_FORK_PATH)/istio-cni
ISTIO_CNI_RELEASE := istio-cni
ISTIO_CNI_NAMESPACE := istio-system
ISTIO_CNI_VALUES_BASE := configs/values/istio-cni/base.yaml
ISTIO_CNI_VALUES_CTX := configs/values/istio-cni/$(CONTEXT).yaml

# Istio Ingress Gateway
ISTIO_INGRESS_CHART_PATH := $(ISTIO_FORK_PATH)/gateways/istio-ingress
ISTIO_INGRESS_RELEASE := istio-ingress
ISTIO_INGRESS_NAMESPACE := istio-ingress
ISTIO_INGRESS_VALUES_BASE := configs/values/istio-ingress/base.yaml
ISTIO_INGRESS_VALUES_CTX := configs/values/istio-ingress/$(CONTEXT).yaml

# =============================================================================
# ISTIO BASE TARGETS
# =============================================================================

.PHONY: istio-base-lint
istio-base-lint: ## Lint Istio base chart
	@echo "$(GREEN)Linting Istio base chart...$(NC)"
	@$(HELM) lint $(ISTIO_BASE_CHART_PATH)

.PHONY: istio-base-template
istio-base-template: ## Render Istio base templates
	@echo "$(GREEN)Rendering Istio base templates...$(NC)"
	@$(HELM) template $(ISTIO_BASE_RELEASE) $(ISTIO_BASE_CHART_PATH) \
		$(if $(wildcard $(ISTIO_BASE_VALUES_BASE)),-f $(ISTIO_BASE_VALUES_BASE)) \
		$(if $(wildcard $(ISTIO_BASE_VALUES_CTX)),-f $(ISTIO_BASE_VALUES_CTX))

.PHONY: istio-base-install
istio-base-install: ## Install Istio base (CRDs)
	@echo "$(GREEN)Installing Istio base...$(NC)"
	@$(KUBECTL) create namespace $(ISTIO_BASE_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(ISTIO_BASE_RELEASE) $(ISTIO_BASE_CHART_PATH) \
		--namespace $(ISTIO_BASE_NAMESPACE) \
		$(if $(wildcard $(ISTIO_BASE_VALUES_BASE)),-f $(ISTIO_BASE_VALUES_BASE)) \
		$(if $(wildcard $(ISTIO_BASE_VALUES_CTX)),-f $(ISTIO_BASE_VALUES_CTX)) \
		--wait

.PHONY: istio-base-uninstall
istio-base-uninstall: ## Uninstall Istio base
	@echo "$(RED)Uninstalling Istio base...$(NC)"
	@$(HELM) uninstall $(ISTIO_BASE_RELEASE) --namespace $(ISTIO_BASE_NAMESPACE) || true

.PHONY: istio-base-status
istio-base-status: ## Show Istio base status
	@echo "$(GREEN)Istio Base Status:$(NC)"
	@$(HELM) status $(ISTIO_BASE_RELEASE) --namespace $(ISTIO_BASE_NAMESPACE) 2>/dev/null || echo "Not installed"

# =============================================================================
# ISTIOD TARGETS
# =============================================================================

.PHONY: istiod-lint
istiod-lint: ## Lint Istiod chart
	@echo "$(GREEN)Linting Istiod chart...$(NC)"
	@$(HELM) lint $(ISTIOD_CHART_PATH)

.PHONY: istiod-template
istiod-template: ## Render Istiod templates
	@echo "$(GREEN)Rendering Istiod templates...$(NC)"
	@$(HELM) template $(ISTIOD_RELEASE) $(ISTIOD_CHART_PATH) \
		$(if $(wildcard $(ISTIOD_VALUES_BASE)),-f $(ISTIOD_VALUES_BASE)) \
		$(if $(wildcard $(ISTIOD_VALUES_CTX)),-f $(ISTIOD_VALUES_CTX))

.PHONY: istiod-install
istiod-install: ## Install Istiod (control plane)
	@echo "$(GREEN)Installing Istiod...$(NC)"
	@$(HELM) upgrade --install $(ISTIOD_RELEASE) $(ISTIOD_CHART_PATH) \
		--namespace $(ISTIOD_NAMESPACE) \
		$(if $(wildcard $(ISTIOD_VALUES_BASE)),-f $(ISTIOD_VALUES_BASE)) \
		$(if $(wildcard $(ISTIOD_VALUES_CTX)),-f $(ISTIOD_VALUES_CTX)) \
		--wait

.PHONY: istiod-upgrade
istiod-upgrade: ## Upgrade Istiod
	@echo "$(GREEN)Upgrading Istiod...$(NC)"
	@$(HELM) upgrade $(ISTIOD_RELEASE) $(ISTIOD_CHART_PATH) \
		--namespace $(ISTIOD_NAMESPACE) \
		$(if $(wildcard $(ISTIOD_VALUES_BASE)),-f $(ISTIOD_VALUES_BASE)) \
		$(if $(wildcard $(ISTIOD_VALUES_CTX)),-f $(ISTIOD_VALUES_CTX)) \
		--wait

.PHONY: istiod-uninstall
istiod-uninstall: ## Uninstall Istiod
	@echo "$(RED)Uninstalling Istiod...$(NC)"
	@$(HELM) uninstall $(ISTIOD_RELEASE) --namespace $(ISTIOD_NAMESPACE) || true

.PHONY: istiod-status
istiod-status: ## Show Istiod status
	@echo "$(GREEN)Istiod Status:$(NC)"
	@$(HELM) status $(ISTIOD_RELEASE) --namespace $(ISTIOD_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(ISTIOD_NAMESPACE) -l app=istiod 2>/dev/null || true

.PHONY: istiod-logs
istiod-logs: ## View Istiod logs
	@$(KUBECTL) logs -n $(ISTIOD_NAMESPACE) -l app=istiod -f --tail=100

# =============================================================================
# ISTIO CNI TARGETS
# =============================================================================

.PHONY: istio-cni-lint
istio-cni-lint: ## Lint Istio CNI chart
	@echo "$(GREEN)Linting Istio CNI chart...$(NC)"
	@$(HELM) lint $(ISTIO_CNI_CHART_PATH)

.PHONY: istio-cni-template
istio-cni-template: ## Render Istio CNI templates
	@echo "$(GREEN)Rendering Istio CNI templates...$(NC)"
	@$(HELM) template $(ISTIO_CNI_RELEASE) $(ISTIO_CNI_CHART_PATH) \
		$(if $(wildcard $(ISTIO_CNI_VALUES_BASE)),-f $(ISTIO_CNI_VALUES_BASE)) \
		$(if $(wildcard $(ISTIO_CNI_VALUES_CTX)),-f $(ISTIO_CNI_VALUES_CTX))

.PHONY: istio-cni-install
istio-cni-install: ## Install Istio CNI
	@echo "$(GREEN)Installing Istio CNI...$(NC)"
	@$(HELM) upgrade --install $(ISTIO_CNI_RELEASE) $(ISTIO_CNI_CHART_PATH) \
		--namespace $(ISTIO_CNI_NAMESPACE) \
		$(if $(wildcard $(ISTIO_CNI_VALUES_BASE)),-f $(ISTIO_CNI_VALUES_BASE)) \
		$(if $(wildcard $(ISTIO_CNI_VALUES_CTX)),-f $(ISTIO_CNI_VALUES_CTX)) \
		--wait

.PHONY: istio-cni-uninstall
istio-cni-uninstall: ## Uninstall Istio CNI
	@echo "$(RED)Uninstalling Istio CNI...$(NC)"
	@$(HELM) uninstall $(ISTIO_CNI_RELEASE) --namespace $(ISTIO_CNI_NAMESPACE) || true

.PHONY: istio-cni-status
istio-cni-status: ## Show Istio CNI status
	@echo "$(GREEN)Istio CNI Status:$(NC)"
	@$(HELM) status $(ISTIO_CNI_RELEASE) --namespace $(ISTIO_CNI_NAMESPACE) 2>/dev/null || echo "Not installed"

# =============================================================================
# ISTIO INGRESS TARGETS
# =============================================================================

.PHONY: istio-ingress-lint
istio-ingress-lint: ## Lint Istio ingress gateway chart
	@echo "$(GREEN)Linting Istio ingress gateway chart...$(NC)"
	@$(HELM) lint $(ISTIO_INGRESS_CHART_PATH)

.PHONY: istio-ingress-template
istio-ingress-template: ## Render Istio ingress gateway templates
	@echo "$(GREEN)Rendering Istio ingress gateway templates...$(NC)"
	@$(HELM) template $(ISTIO_INGRESS_RELEASE) $(ISTIO_INGRESS_CHART_PATH) \
		$(if $(wildcard $(ISTIO_INGRESS_VALUES_BASE)),-f $(ISTIO_INGRESS_VALUES_BASE)) \
		$(if $(wildcard $(ISTIO_INGRESS_VALUES_CTX)),-f $(ISTIO_INGRESS_VALUES_CTX))

.PHONY: istio-ingress-install
istio-ingress-install: ## Install Istio ingress gateway
	@echo "$(GREEN)Installing Istio ingress gateway...$(NC)"
	@$(KUBECTL) create namespace $(ISTIO_INGRESS_NAMESPACE) --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) upgrade --install $(ISTIO_INGRESS_RELEASE) $(ISTIO_INGRESS_CHART_PATH) \
		--namespace $(ISTIO_INGRESS_NAMESPACE) \
		$(if $(wildcard $(ISTIO_INGRESS_VALUES_BASE)),-f $(ISTIO_INGRESS_VALUES_BASE)) \
		$(if $(wildcard $(ISTIO_INGRESS_VALUES_CTX)),-f $(ISTIO_INGRESS_VALUES_CTX)) \
		--wait

.PHONY: istio-ingress-uninstall
istio-ingress-uninstall: ## Uninstall Istio ingress gateway
	@echo "$(RED)Uninstalling Istio ingress gateway...$(NC)"
	@$(HELM) uninstall $(ISTIO_INGRESS_RELEASE) --namespace $(ISTIO_INGRESS_NAMESPACE) || true

.PHONY: istio-ingress-status
istio-ingress-status: ## Show Istio ingress gateway status
	@echo "$(GREEN)Istio Ingress Gateway Status:$(NC)"
	@$(HELM) status $(ISTIO_INGRESS_RELEASE) --namespace $(ISTIO_INGRESS_NAMESPACE) 2>/dev/null || echo "Not installed"
	@echo ""
	@$(KUBECTL) get pods -n $(ISTIO_INGRESS_NAMESPACE) 2>/dev/null || true

.PHONY: istio-ingress-logs
istio-ingress-logs: ## View Istio ingress gateway logs
	@$(KUBECTL) logs -n $(ISTIO_INGRESS_NAMESPACE) -l app=istio-ingress -f --tail=100

# =============================================================================
# ISTIO FULL STACK
# =============================================================================

.PHONY: istio-install
istio-install: istio-base-install istiod-install istio-ingress-install ## Install full Istio stack (base + istiod + ingress)

.PHONY: istio-uninstall
istio-uninstall: istio-ingress-uninstall istiod-uninstall istio-base-uninstall ## Uninstall full Istio stack

.PHONY: istio-status
istio-status: istio-base-status istiod-status istio-ingress-status ## Show status of full Istio stack

# =============================================================================
# ISTIO FORK SYNC
# =============================================================================

.PHONY: istio-sync
istio-sync: ## Sync fork with upstream
	@echo "$(GREEN)Syncing Istio fork with upstream...$(NC)"
	@cd forks/istio && git fetch upstream && git merge upstream/master --no-edit

# =============================================================================
# OCI PACKAGING & PUBLISHING
# =============================================================================

.PHONY: istio-base-package
istio-base-package: ## Package Istio base chart
	@$(PUSH_CHART) --chart $(ISTIO_BASE_CHART_PATH) --package-only

.PHONY: istio-base-push
istio-base-push: ## Push Istio base chart to OCI registry (REGISTRY=local)
	@$(PUSH_CHART) --chart $(ISTIO_BASE_CHART_PATH) --registry $(REGISTRY)

.PHONY: istiod-package
istiod-package: ## Package Istiod chart
	@$(PUSH_CHART) --chart $(ISTIOD_CHART_PATH) --package-only

.PHONY: istiod-push
istiod-push: ## Push Istiod chart to OCI registry (REGISTRY=local)
	@$(PUSH_CHART) --chart $(ISTIOD_CHART_PATH) --registry $(REGISTRY)

.PHONY: istio-cni-package
istio-cni-package: ## Package Istio CNI chart
	@$(PUSH_CHART) --chart $(ISTIO_CNI_CHART_PATH) --package-only

.PHONY: istio-cni-push
istio-cni-push: ## Push Istio CNI chart to OCI registry (REGISTRY=local)
	@$(PUSH_CHART) --chart $(ISTIO_CNI_CHART_PATH) --registry $(REGISTRY)

.PHONY: istio-ingress-package
istio-ingress-package: ## Package Istio ingress gateway chart
	@$(PUSH_CHART) --chart $(ISTIO_INGRESS_CHART_PATH) --package-only

.PHONY: istio-ingress-push
istio-ingress-push: ## Push Istio ingress gateway chart to OCI registry (REGISTRY=local)
	@$(PUSH_CHART) --chart $(ISTIO_INGRESS_CHART_PATH) --registry $(REGISTRY)

.PHONY: istio-push-all
istio-push-all: istio-base-push istiod-push istio-cni-push istio-ingress-push ## Push all Istio charts to OCI registry

# =============================================================================
# MIRRORING (UPSTREAM → OCI REGISTRY)
# =============================================================================

.PHONY: istio-base-mirror
istio-base-mirror: ## Mirror Istio base chart + images to DOCR (VERSION=<ver>)
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart base $(if $(VERSION),--version $(VERSION))

.PHONY: istio-base-images
istio-base-images: ## List container images in Istio base chart
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart base --dry-run --images-only -o json | jq -r '.charts[].versions[].images[].source'

.PHONY: istiod-mirror
istiod-mirror: ## Mirror Istiod chart + images to DOCR (VERSION=<ver>)
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart istiod $(if $(VERSION),--version $(VERSION))

.PHONY: istiod-images
istiod-images: ## List container images in Istiod chart
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart istiod --dry-run --images-only -o json | jq -r '.charts[].versions[].images[].source'

.PHONY: istio-cni-mirror
istio-cni-mirror: ## Mirror Istio CNI chart + images to DOCR (VERSION=<ver>)
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart cni $(if $(VERSION),--version $(VERSION))

.PHONY: istio-cni-images
istio-cni-images: ## List container images in Istio CNI chart
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart cni --dry-run --images-only -o json | jq -r '.charts[].versions[].images[].source'

.PHONY: istio-ingress-mirror
istio-ingress-mirror: ## Mirror Istio ingress gateway chart + images to DOCR (VERSION=<ver>)
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart gateway $(if $(VERSION),--version $(VERSION))

.PHONY: istio-ingress-images
istio-ingress-images: ## List container images in Istio ingress gateway chart
	@$(LAZYOCI) mirror --config $(MIRROR_CONFIG) --chart gateway --dry-run --images-only -o json | jq -r '.charts[].versions[].images[].source'

.PHONY: istio-mirror-all
istio-mirror-all: istio-base-mirror istiod-mirror istio-cni-mirror istio-ingress-mirror ## Mirror all Istio charts
