# Customer-facing composition. Reads the generated permission catalog, resolves
# per-service resource scoping, and creates either one role per integration
# (per_service) or a single shared role carrying one policy per integration.

# Auto-generate a stable external ID when the caller doesn't supply one. The value
# is created once and persists in state across applies; override var.external_id to
# use a Relyance-provided or bring-your-own value.
resource "random_uuid" "external_id" {
  count = var.external_id == null ? 1 : 0
}

data "aws_partition" "current" {}

locals {
  external_id = var.external_id != null ? var.external_id : random_uuid.external_id[0].result

  # Partition-aware "all resources" ARNs (commercial aws / aws-us-gov / aws-cn).
  all_buckets = "arn:${data.aws_partition.current.partition}:s3:::*"

  # Source of truth -- the committed permission catalog consumed via jsondecode.
  catalog = jsondecode(file("${path.module}/generated/permissions.json")).integrations

  enabled = { for k, v in var.integrations : k => v if v.enabled }

  # Resolve each statement's Resource list from its scope + the caller's intent.
  # For bucket/object/table scopes the caller must have set resource_arns or
  # all_resources (enforced by variable validation); all_resources -> "*".
  resolved_groups = {
    for k, cfg in local.enabled : k => {
      managed_policy_arns = local.catalog[k].managed_policy_arns
      statements = [
        for s in local.catalog[k].statements : {
          # IAM Sid must be alphanumeric only; strip separators and namespace by integration.
          sid     = replace("${k}${s.sid}", "/[^0-9A-Za-z]/", "")
          actions = s.actions
          resources = (
            s.scope == "bucket" ? (cfg.all_resources ? [local.all_buckets] : cfg.resource_arns) :
            s.scope == "object" ? [for a in(cfg.all_resources ? [local.all_buckets] : cfg.resource_arns) : "${a}/*"] :
            s.scope == "table" ? (cfg.all_resources ? ["*"] : flatten([for a in cfg.resource_arns : [a, "${a}/index/*"]])) :
            ["*"] # account / global -- not resource-scopable in IAM
          )
        }
      ]
    }
  }

  # One role per integration, or one shared role holding every group.
  roles = var.role_topology == "shared" ? {
    (var.shared_role_name) = { policies = local.resolved_groups }
    } : {
    for k, g in local.resolved_groups : "${var.role_name_prefix}-${k}" => { policies = { (k) = g } }
  }
}

module "role" {
  source   = "./modules/service-role"
  for_each = local.roles

  role_name                = each.key
  relyance_principal_arns  = var.relyance_principal_arns
  external_id              = local.external_id
  permissions_boundary_arn = var.permissions_boundary_arn
  max_session_duration     = var.max_session_duration
  policies                 = each.value.policies
  use_inline_policies      = var.role_topology == "shared"
  tags                     = var.tags
}
