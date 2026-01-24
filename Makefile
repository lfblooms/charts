# Charts Repository Makefile
# Manage Helm chart installations to KIND cluster

SHELL := /bin/bash
.DEFAULT_GOAL := help

# Cluster configuration
CLUSTER_NAME ?= kind
KUBECONFIG ?= $(HOME)/.kube/config

# Helm settings
HELM := helm
KUBECTL := kubectl

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

# =============================================================================
# HELP
# =============================================================================

.PHONY: help
help: ## Show this help
	@echo ""
	@echo "Charts Repository - Helm Chart Management"
	@echo "=========================================="
	@echo ""
	@echo "Cluster Management:"
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E '(cluster|kind)' | sed 's/:.*## /\t/' | awk 'BEGIN {FS = "\t"}; {printf "  $(GREEN)%-25s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "All Charts:"
	@grep -hE '^(install-all|uninstall-all|status-all):.*?## .*$$' $(MAKEFILE_LIST) | sed 's/:.*## /\t/' | awk 'BEGIN {FS = "\t"}; {printf "  $(GREEN)%-25s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "Infisical:"
	@grep -hE '^infisical[a-zA-Z_-]*:.*?## .*$$' $(MAKEFILE_LIST) | sed 's/:.*## /\t/' | awk 'BEGIN {FS = "\t"}; {printf "  $(GREEN)%-25s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "Utilities:"
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -vE '(cluster|kind|install-all|uninstall-all|status-all|infisical)' | sed 's/:.*## /\t/' | awk 'BEGIN {FS = "\t"}; {printf "  $(GREEN)%-25s$(NC) %s\n", $$1, $$2}'
	@echo ""

# =============================================================================
# CLUSTER MANAGEMENT
# =============================================================================

.PHONY: cluster-info
cluster-info: ## Show cluster information
	@echo "$(GREEN)Cluster Context:$(NC)"
	@$(KUBECTL) config current-context
	@echo ""
	@echo "$(GREEN)Nodes:$(NC)"
	@$(KUBECTL) get nodes
	@echo ""
	@echo "$(GREEN)Namespaces:$(NC)"
	@$(KUBECTL) get namespaces

.PHONY: kind-create
kind-create: ## Create KIND cluster
	@if kind get clusters | grep -q $(CLUSTER_NAME); then \
		echo "$(YELLOW)Cluster '$(CLUSTER_NAME)' already exists$(NC)"; \
	else \
		echo "$(GREEN)Creating KIND cluster '$(CLUSTER_NAME)'...$(NC)"; \
		kind create cluster --name $(CLUSTER_NAME); \
	fi

.PHONY: kind-delete
kind-delete: ## Delete KIND cluster
	@echo "$(RED)Deleting KIND cluster '$(CLUSTER_NAME)'...$(NC)"
	@kind delete cluster --name $(CLUSTER_NAME)

.PHONY: kind-load-images
kind-load-images: ## Load Docker images into KIND cluster
	@echo "$(GREEN)Loading images into KIND...$(NC)"
	@# Add image loading commands as needed

# =============================================================================
# ALL CHARTS
# =============================================================================

.PHONY: install-all
install-all: infisical-install ## Install all charts

.PHONY: uninstall-all
uninstall-all: infisical-uninstall ## Uninstall all charts

.PHONY: status-all
status-all: infisical-status ## Show status of all charts

# =============================================================================
# INCLUDE CHART-SPECIFIC MAKEFILES
# =============================================================================

include makefiles/*.mk
