output "discovery_role_arn" {
  description = "DiscoveryRole ARN -- the \"Delegated Resource Explorer Reader Role ARN\" form field."
  value       = module.discovery.role_arn
}

output "org_view_arn" {
  description = "Organization-wide Resource Explorer view ARN -- the \"Delegated Resource Explorer View ARN\" form field."
  value       = local.org_view_arn
}

output "delegated_admin_account_id" {
  description = "This delegated administrator account's ID."
  value       = data.aws_caller_identity.current.account_id
}

output "scanner_role_name" {
  description = "GlobalResourceScannerRole name (deployed org-wide)."
  value       = local.scanner_name
}

output "stack_set_ids" {
  description = "IDs of the created StackSets."
  value = {
    scanner_role = aws_cloudformation_stack_set.scanner_role.id
    local_index  = var.create_resource_explorer ? aws_cloudformation_stack_set.local_index[0].id : null
  }
}
