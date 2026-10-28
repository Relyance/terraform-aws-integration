terraform {
  required_version = ">= 1.5"
  required_providers {
    aws    = { source = "hashicorp/aws", version = ">= 5.0, < 7.0" }
    random = { source = "hashicorp/random", version = ">= 3.0" }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "external_id" {
  description = "Per-tenant external ID provided by Relyance onboarding."
  type        = string
}

module "relyance_inventory" {
  source       = "../.."
  external_id  = var.external_id
  integrations = { aws = {} }
}

output "relyance_form_values" {
  value = module.relyance_inventory.relyance_form_values
}
