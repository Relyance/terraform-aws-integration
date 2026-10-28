# Org-scan: MANAGEMENT-account half. Apply with management-account credentials.
#
# Creates the org-mapping role, registers the delegated administrator (DA) for
# Resource Explorer and CloudFormation StackSets, and (optionally) creates the
# scanner role + local Resource Explorer index for the management account itself.
# Outputs feed the org-delegated module (external_id + organization identifiers).

resource "random_uuid" "external_id" {
  count = var.external_id == null ? 1 : 0
}

data "aws_partition" "current" {}
data "aws_organizations_organization" "this" {}

locals {
  external_id  = var.external_id != null ? var.external_id : random_uuid.external_id[0].result
  readonly_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/ReadOnlyAccess"

  # Optional prefix/suffix applied to every created resource name.
  org_reader_name = "${var.name_prefix}${var.org_reader_role_name}${var.name_suffix}"
  scanner_name    = "${var.name_prefix}${var.scanner_role_name}${var.name_suffix}"

  scanner_statements = [{
    sid       = "ResourceExplorerAndTags"
    actions   = ["resource-explorer-2:GetView", "resource-explorer-2:Search", "resource-explorer-2:ListViews", "tag:GetTagKeys", "tag:GetTagValues", "tag:GetResources"]
    resources = ["*"]
  }]
}

# Register the DA account for Resource Explorer + CloudFormation StackSets.
resource "aws_organizations_delegated_administrator" "resource_explorer" {
  count             = var.register_resource_explorer_delegated_admin ? 1 : 0
  account_id        = var.delegated_admin_account_id
  service_principal = "resource-explorer-2.amazonaws.com"
}

resource "aws_organizations_delegated_administrator" "stacksets" {
  count             = var.register_stacksets_delegated_admin ? 1 : 0
  account_id        = var.delegated_admin_account_id
  service_principal = "member.org.stacksets.cloudformation.amazonaws.com"
}

# OrgReaderRole.
module "org_reader" {
  source = "../service-role"

  role_name                = local.org_reader_name
  relyance_principal_arns  = var.relyance_principal_arns
  external_id              = local.external_id
  permissions_boundary_arn = var.permissions_boundary_arn
  max_session_duration     = var.max_session_duration
  tags                     = var.tags

  policies = {
    org_mapping = {
      statements = [{
        sid       = "OrgAndIdentityMapping"
        actions   = ["organizations:List*", "organizations:Describe*", "sso:List*", "sso:Describe*", "identitystore:List*", "identitystore:Describe*"]
        resources = ["*"]
      }]
      managed_policy_arns = []
    }
  }
}

# Scanner role for the management account itself (StackSets do not target it).
module "management_scanner" {
  count  = var.include_management_account ? 1 : 0
  source = "../service-role"

  role_name                = local.scanner_name
  relyance_principal_arns  = var.relyance_principal_arns
  external_id              = local.external_id
  permissions_boundary_arn = var.permissions_boundary_arn
  max_session_duration     = var.max_session_duration
  tags                     = var.tags

  policies = {
    scanner = {
      statements          = local.scanner_statements
      managed_policy_arns = [local.readonly_arn]
    }
  }
}

resource "aws_resourceexplorer2_index" "management_local" {
  count = var.include_management_account && var.create_management_local_index ? 1 : 0
  type  = "LOCAL"
  tags  = var.tags
}
