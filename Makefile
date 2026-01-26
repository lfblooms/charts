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

# Context configuration (local, cloud-prod, etc.)
CONTEXT ?= local

# =============================================================================
# HELP
# =============================================================================

.PHONY: help
help: ## Show this help
	@echo ""
	@echo "Charts Repository - Helm Chart Management"
	@echo "=========================================="
	@echo ""
	@echo "Usage: make <target> [CONTEXT=<context>]"
	@echo "Current context: $(CONTEXT)"
	@echo ""
	@echo "$(YELLOW)Cluster Management:$(NC)"
	@grep -hE '^(cluster|kind)[a-zA-Z_-]*:.*?## .*$$' $(MAKEFILE_LIST) | sed 's/:.*## /\t/' | awk 'BEGIN {FS = "\t"}; {printf "  $(GREEN)%-30s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)GitOps & CD:$(NC)"
	@grep -hE '^argocd[a-zA-Z_-]*:.*?## .*$$' $(MAKEFILE_LIST) | head -6 | sed 's/:.*## /\t/' | awk 'BEGIN {FS = "\t"}; {printf "  $(GREEN)%-30s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Secrets Management:$(NC)"
	@grep -hE '^(external-secrets|vault|infisical)[a-zA-Z_-]*:.*?## .*$$' $(MAKEFILE_LIST) | grep -E '(install|status)' | sed 's/:.*## /\t/' | awk 'BEGIN {FS = "\t"}; {printf "  $(GREEN)%-30s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Networking:$(NC)"
	@grep -hE '^(ingress-nginx|istio|external-dns)[a-zA-Z_-]*:.*?## .*$$' $(MAKEFILE_LIST) | grep -E '(install|status)' | sed 's/:.*## /\t/' | awk 'BEGIN {FS = "\t"}; {printf "  $(GREEN)%-30s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Observability:$(NC)"
	@grep -hE '^(grafana|loki|tempo|mimir|prometheus|kube-prometheus-stack)[a-zA-Z_-]*:.*?## .*$$' $(MAKEFILE_LIST) | grep -E '(install|status)' | sed 's/:.*## /\t/' | awk 'BEGIN {FS = "\t"}; {printf "  $(GREEN)%-30s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Security & Policy:$(NC)"
	@grep -hE '^(cert-manager|kyverno|policy-reporter|kiali)[a-zA-Z_-]*:.*?## .*$$' $(MAKEFILE_LIST) | grep -E '(install|status)' | sed 's/:.*## /\t/' | awk 'BEGIN {FS = "\t"}; {printf "  $(GREEN)%-30s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Identity & Access:$(NC)"
	@grep -hE '^keycloak[a-zA-Z_-]*:.*?## .*$$' $(MAKEFILE_LIST) | grep -E '(install|status)' | sed 's/:.*## /\t/' | awk 'BEGIN {FS = "\t"}; {printf "  $(GREEN)%-30s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Storage & Registry:$(NC)"
	@grep -hE '^(harbor|minio)[a-zA-Z_-]*:.*?## .*$$' $(MAKEFILE_LIST) | grep -E '(install|status)' | sed 's/:.*## /\t/' | awk 'BEGIN {FS = "\t"}; {printf "  $(GREEN)%-30s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Network Management:$(NC)"
	@grep -hE '^tailscale[a-zA-Z_-]*:.*?## .*$$' $(MAKEFILE_LIST) | grep -E '(install|status)' | sed 's/:.*## /\t/' | awk 'BEGIN {FS = "\t"}; {printf "  $(GREEN)%-30s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "Run 'make help-<chart>' for detailed targets (e.g., make help-argocd)"
	@echo ""

# Chart-specific help targets
.PHONY: help-argocd
help-argocd: ## Show ArgoCD targets
	@echo "$(YELLOW)ArgoCD Targets:$(NC)"
	@grep -hE '^argocd[a-zA-Z_-]*:.*?## .*$$' $(MAKEFILE_LIST) | sed 's/:.*## /\t/' | awk 'BEGIN {FS = "\t"}; {printf "  $(GREEN)%-30s$(NC) %s\n", $$1, $$2}'

.PHONY: help-istio
help-istio: ## Show Istio targets
	@echo "$(YELLOW)Istio Targets:$(NC)"
	@grep -hE '^(istio|istiod)[a-zA-Z_-]*:.*?## .*$$' $(MAKEFILE_LIST) | sed 's/:.*## /\t/' | awk 'BEGIN {FS = "\t"}; {printf "  $(GREEN)%-30s$(NC) %s\n", $$1, $$2}'

.PHONY: help-observability
help-observability: ## Show observability targets (Grafana, Loki, Tempo, Mimir, Prometheus)
	@echo "$(YELLOW)Observability Targets:$(NC)"
	@grep -hE '^(grafana|loki|tempo|mimir|prometheus|kube-prometheus-stack|observability)[a-zA-Z_-]*:.*?## .*$$' $(MAKEFILE_LIST) | sed 's/:.*## /\t/' | awk 'BEGIN {FS = "\t"}; {printf "  $(GREEN)%-30s$(NC) %s\n", $$1, $$2}'

.PHONY: help-vault
help-vault: ## Show Vault targets
	@echo "$(YELLOW)Vault Targets:$(NC)"
	@grep -hE '^vault[a-zA-Z_-]*:.*?## .*$$' $(MAKEFILE_LIST) | sed 's/:.*## /\t/' | awk 'BEGIN {FS = "\t"}; {printf "  $(GREEN)%-30s$(NC) %s\n", $$1, $$2}'

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
