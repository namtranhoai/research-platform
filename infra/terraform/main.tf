# Research Platform - Minimal Infrastructure
# Local/mock backend - ready for cloud expansion

terraform {
  required_version = ">= 1.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
  backend "local" {
    path = "terraform.tfstate"
  }
}

locals {
  namespace = "research-platform-${var.environment}"
  labels = {
    app         = "research-platform"
    environment = var.environment
    managed-by  = "terraform"
  }
}

# Mock/minimal resource - outputs config for reference
resource "local_file" "config" {
  content = jsonencode({
    namespace   = local.namespace
    environment = var.environment
    labels      = local.labels
  })
  filename = "${path.module}/config-${var.environment}.json"
}

# Unique suffix for resources (mock)
resource "random_id" "suffix" {
  byte_length = 4
}

# Output for pipeline
output "environment" {
  value = var.environment
}

output "namespace" {
  value = local.namespace
}

output "labels" {
  value     = local.labels
  sensitive = false
}
