# Org-scan composition: runs BOTH halves in one apply, for operators who hold
# management AND delegated-administrator credentials simultaneously. When the two
# accounts are owned by different teams, apply modules/org-management and
# modules/org-delegated separately instead (passing org-management's outputs in).
#
# Ordering: management half registers the DA and emits org identifiers; the
# delegated half consumes them. Terraform sequences this via the module references.

data "aws_caller_identity" "delegated" {
  provider = aws.delegated
}

module "management" {
  source    = "../org-management"
  providers = { aws = aws.management }

  relyance_principal_arns                    = var.relyance_principal_arns
  external_id                                = var.external_id
  delegated_admin_account_id                 = data.aws_caller_identity.delegated.account_id
  org_reader_role_name                       = var.org_reader_role_name
  scanner_role_name                          = var.scanner_role_name
  register_resource_explorer_delegated_admin = var.register_resource_explorer_delegated_admin
  register_stacksets_delegated_admin         = var.register_stacksets_delegated_admin
  include_management_account                 = var.include_management_account
  create_management_local_index              = var.create_resource_explorer
  permissions_boundary_arn                   = var.permissions_boundary_arn
  max_session_duration                       = var.max_session_duration
  tags                                       = var.tags
  name_prefix                                = var.name_prefix
  name_suffix                                = var.name_suffix
}

module "delegated" {
  source    = "../org-delegated"
  providers = { aws = aws.delegated }

  # The delegated half (aggregator index, org view, service-managed StackSets) must
  # not start until the management half has registered the DA for Resource Explorer
  # and CloudFormation StackSets. Output references alone don't guarantee that
  # ordering, so depend on the whole module explicitly.
  depends_on = [module.management]

  relyance_principal_arns        = var.relyance_principal_arns
  external_id                    = module.management.external_id
  organization_id                = module.management.organization_id
  management_account_id          = module.management.management_account_id
  organization_root_id           = module.management.organization_root_id
  target_organizational_unit_ids = var.target_organizational_unit_ids
  discovery_role_name            = var.discovery_role_name
  scanner_role_name              = var.scanner_role_name
  org_view_name                  = var.org_view_name
  create_resource_explorer       = var.create_resource_explorer
  existing_org_view_arn          = var.existing_org_view_arn
  index_regions                  = var.index_regions
  home_region                    = var.home_region
  permissions_boundary_arn       = var.permissions_boundary_arn
  max_session_duration           = var.max_session_duration
  tags                           = var.tags
  name_prefix                    = var.name_prefix
  name_suffix                    = var.name_suffix
}
