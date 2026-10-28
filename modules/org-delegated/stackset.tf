# Service-managed StackSets run from this (DA) account, call_as = DELEGATED_ADMIN,
# targeting the entire org (or specific OUs) and auto-deploying to new accounts.

locals {
  scanner_role_properties = merge(
    {
      RoleName           = local.scanner_name
      MaxSessionDuration = var.max_session_duration
      AssumeRolePolicyDocument = {
        Version = "2012-10-17"
        Statement = [{
          Effect    = "Allow"
          Principal = { AWS = var.relyance_principal_arns }
          Action    = ["sts:AssumeRole", "sts:TagSession"]
          Condition = { StringEquals = { "sts:ExternalId" = var.external_id } }
        }]
      }
      ManagedPolicyArns = [local.readonly_arn]
      Policies = [{
        PolicyName = "RelyanceScannerTagRead"
        PolicyDocument = {
          Version   = "2012-10-17"
          Statement = [{ Sid = "TagRead", Effect = "Allow", Action = local.scanner_statements[0].actions, Resource = "*" }]
        }
      }]
      Tags = [for k, v in var.tags : { Key = k, Value = v }]
    },
    var.permissions_boundary_arn != null ? { PermissionsBoundary = var.permissions_boundary_arn } : {},
  )

  scanner_role_template = {
    AWSTemplateFormatVersion = "2010-09-09"
    Description              = "Relyance organization-wide read-only resource scanner role"
    Resources                = { GlobalResourceScannerRole = { Type = "AWS::IAM::Role", Properties = local.scanner_role_properties } }
  }

  local_index_template = {
    AWSTemplateFormatVersion = "2010-09-09"
    Description              = "Relyance local Resource Explorer index"
    Resources                = { RelyanceLocalIndex = { Type = "AWS::ResourceExplorer2::Index", Properties = { Type = "LOCAL", Tags = var.tags } } }
  }
}

resource "aws_cloudformation_stack_set" "scanner_role" {
  name             = "${local.scanner_name}-stackset"
  description      = "Relyance org-wide read-only resource scanner role"
  permission_model = "SERVICE_MANAGED"
  capabilities     = ["CAPABILITY_NAMED_IAM"]
  call_as          = "DELEGATED_ADMIN"
  template_body    = jsonencode(local.scanner_role_template)
  tags             = var.tags

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }
}

resource "aws_cloudformation_stack_set_instance" "scanner_role" {
  stack_set_name            = aws_cloudformation_stack_set.scanner_role.name
  call_as                   = "DELEGATED_ADMIN"
  stack_set_instance_region = var.home_region

  deployment_targets {
    organizational_unit_ids = local.target_ou_ids
  }
}

resource "aws_cloudformation_stack_set" "local_index" {
  count            = var.create_resource_explorer ? 1 : 0
  name             = "${var.name_prefix}Relyance-LocalResourceExplorerIndex${var.name_suffix}-stackset"
  description      = "Relyance local Resource Explorer index"
  permission_model = "SERVICE_MANAGED"
  call_as          = "DELEGATED_ADMIN"
  template_body    = jsonencode(local.local_index_template)
  tags             = var.tags

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }
}

resource "aws_cloudformation_stack_set_instance" "local_index" {
  for_each = var.create_resource_explorer ? toset(local.index_regions) : []

  stack_set_name            = aws_cloudformation_stack_set.local_index[0].name
  call_as                   = "DELEGATED_ADMIN"
  stack_set_instance_region = each.value

  deployment_targets {
    organizational_unit_ids = local.target_ou_ids
  }
}
