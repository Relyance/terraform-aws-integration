# Org-scan: DELEGATED-ADMINISTRATOR half. Apply with DA-account credentials.
#
# Creates the Resource Explorer query role (DiscoveryRole), the aggregator index +
# org view, and the service-managed StackSets that deploy the scanner role and local
# Resource Explorer indexes across the organization. Requires the org-management
# module to have run first (DA registrations + external_id + org identifiers).

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  readonly_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/ReadOnlyAccess"

  # Optional prefix/suffix applied to every created resource name. scanner_name
  # MUST match the management module's (the scanner builds the role ARN per account).
  discovery_name = "${var.name_prefix}${var.discovery_role_name}${var.name_suffix}"
  scanner_name   = "${var.name_prefix}${var.scanner_role_name}${var.name_suffix}"
  view_name      = "${var.name_prefix}${var.org_view_name}${var.name_suffix}"

  index_regions = length(var.index_regions) > 0 ? var.index_regions : [var.home_region]

  target_ou_ids = (
    length(var.target_organizational_unit_ids) > 0
    ? var.target_organizational_unit_ids
    : [var.organization_root_id]
  )

  org_view_arn = (
    var.create_resource_explorer
    ? aws_resourceexplorer2_view.org[0].arn
    : var.existing_org_view_arn
  )

  # The per-account scanner role reads resource detail + tags via ReadOnlyAccess.
  # Resource Explorer is queried only by DiscoveryRole in the DA account, so this
  # role needs no resource-explorer-2 actions.
  scanner_statements = [{
    sid       = "TagRead"
    actions   = ["tag:GetTagKeys", "tag:GetTagValues", "tag:GetResources"]
    resources = ["*"]
  }]
}

resource "terraform_data" "validate_inputs" {
  lifecycle {
    precondition {
      condition     = var.create_resource_explorer || var.existing_org_view_arn != null
      error_message = "existing_org_view_arn is required when create_resource_explorer = false."
    }
    precondition {
      condition     = length(var.target_organizational_unit_ids) > 0 || var.organization_root_id != null
      error_message = "Provide organization_root_id (from org-management) or target_organizational_unit_ids."
    }
  }
}

# DiscoveryRole.
module "discovery" {
  source = "../service-role"

  role_name                = local.discovery_name
  relyance_principal_arns  = var.relyance_principal_arns
  external_id              = var.external_id
  permissions_boundary_arn = var.permissions_boundary_arn
  max_session_duration     = var.max_session_duration
  tags                     = var.tags

  policies = {
    org_view_discovery = {
      statements = [{
        sid       = "OrgViewDiscovery"
        actions   = ["resource-explorer-2:Search", "resource-explorer-2:GetView", "resource-explorer-2:ListIndexes", "resource-explorer-2:ListViews"]
        resources = ["*"]
      }]
      managed_policy_arns = []
    }
  }
}

# Resource Explorer aggregator index (one per org) + org-wide view.
resource "aws_resourceexplorer2_index" "aggregator" {
  count = var.create_resource_explorer ? 1 : 0
  type  = "AGGREGATOR"
  tags  = var.tags
}

resource "aws_resourceexplorer2_view" "org" {
  count = var.create_resource_explorer ? 1 : 0

  name       = local.view_name
  scope      = "arn:${data.aws_partition.current.partition}:organizations::${var.management_account_id}:organization/${var.organization_id}"
  depends_on = [aws_resourceexplorer2_index.aggregator]
  tags       = var.tags
}
