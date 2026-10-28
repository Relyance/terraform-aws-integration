# Org-scan, STEP 1 of 2: apply with MANAGEMENT-account credentials.
#
# Registers the delegated administrator (DA) for Resource Explorer + StackSets,
# creates OrgReaderRole and the management account's scanner role + local index.
# Copy the outputs (external_id + organization IDs) into step 2 (../delegated).

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws    = { source = "hashicorp/aws", version = ">= 5.0, < 7.0" }
    random = { source = "hashicorp/random", version = ">= 3.0" }
  }
}

provider "aws" {
  region = "us-east-1"
  # management-account credentials (profile / assume_role)
}

module "org_management" {
  source = "../../../modules/org-management"

  delegated_admin_account_id = "111111111111" # the DA (member) account ID
  # relyance_principal_arns defaults to the Relyance production principal.
  # external_id auto-generates (see output) -- feed it into step 2.

  tags = { ManagedBy = "terraform", Vendor = "relyance" }
}

# Feed these into ../delegated:
output "external_id" { value = module.org_management.external_id }
output "organization_id" { value = module.org_management.organization_id }
output "management_account_id" { value = module.org_management.management_account_id }
output "organization_root_id" { value = module.org_management.organization_root_id }
output "org_reader_role_arn" { value = module.org_management.org_reader_role_arn }
