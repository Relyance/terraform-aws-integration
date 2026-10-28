# Org-scan, STEP 2 of 2: apply with DELEGATED-ADMIN (DA) account credentials.
#
# Run AFTER ../management. Paste that step's outputs into the variables below.
# Creates DiscoveryRole, the Resource Explorer aggregator index + org view, and
# the service-managed StackSets that roll the scanner role + local indexes out
# across the organization.

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0, < 7.0" }
  }
}

provider "aws" {
  region = "us-east-1"
  # delegated-administrator (DA) account credentials (profile / assume_role)
}

# From the management step's outputs:
variable "external_id" { type = string }
variable "organization_id" { type = string }
variable "management_account_id" { type = string }
variable "organization_root_id" { type = string }

module "org_delegated" {
  source = "../../../modules/org-delegated"

  external_id           = var.external_id
  organization_id       = var.organization_id
  management_account_id = var.management_account_id
  organization_root_id  = var.organization_root_id

  index_regions = ["us-east-1", "us-west-2"]
  home_region   = "us-east-1"

  tags = { ManagedBy = "terraform", Vendor = "relyance" }
}

output "relyance_org_scan_form" {
  value = {
    external_id        = var.external_id
    discovery_role_arn = module.org_delegated.discovery_role_arn
    org_view_arn       = module.org_delegated.org_view_arn
    scanner_role_name  = module.org_delegated.scanner_role_name
  }
}
