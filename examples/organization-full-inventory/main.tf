# Example: organization-wide AWS resource discovery (delegated-administrator model).
#
# Creates, across three account roles:
#   * OrgReaderRole + the management account's own scanner role + RE delegated-admin
#     registration + a management-account local index (management account)
#   * DiscoveryRole + the Resource Explorer aggregator index + org view + the
#     service-managed StackSets (delegated administrator account)
#   * GlobalResourceScannerRole + a local Resource Explorer index in every member
#     account/Region (via service-managed StackSet)
#
# Run with credentials for both the management account and the delegated
# administrator (DA) account.

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws    = { source = "hashicorp/aws", version = ">= 5.0, < 7.0" }
    random = { source = "hashicorp/random", version = ">= 3.0" }
  }
}

# Organizations management account.
provider "aws" {
  alias  = "management"
  region = "us-east-1"
  # profile / assume_role for the management account
}

# Delegated administrator (DA) account -- the operational hub.
provider "aws" {
  alias  = "delegated"
  region = "us-east-1"
  # profile / assume_role for the DA account
}

module "relyance_org" {
  source = "../../modules/org-scan"

  providers = {
    aws.management = aws.management
    aws.delegated  = aws.delegated
  }

  # relyance_principal_arns defaults to the Relyance production principal.
  # external_id auto-generates a stable UUID (see outputs).

  # Regions to enable local Resource Explorer indexes in (every Region you want
  # discovered across the org):
  index_regions = ["us-east-1", "us-west-2"]
  home_region   = "us-east-1"

  # Scope to specific OUs, or leave empty for the whole org:
  target_organizational_unit_ids = []

  tags = {
    ManagedBy = "terraform"
    Vendor    = "relyance"
  }
}

# Transcribe these into the Relyance "Organization Scan" form:
output "relyance_org_scan_form" {
  value = module.relyance_org.relyance_org_scan_form
}
