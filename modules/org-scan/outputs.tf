# Outputs map 1:1 onto the Relyance "Organization Scan" form, assembled from both
# halves of the deployment.

output "org_reader_role_arn" {
  description = "OrgReaderRole ARN (management account)."
  value       = module.management.org_reader_role_arn
}

output "discovery_role_arn" {
  description = "DiscoveryRole ARN (delegated administrator account)."
  value       = module.delegated.discovery_role_arn
}

output "org_view_arn" {
  description = "Organization-wide Resource Explorer view ARN."
  value       = module.delegated.org_view_arn
}

output "scanner_role_name" {
  description = "GlobalResourceScannerRole name (identical in every account)."
  value       = module.delegated.scanner_role_name
}

output "delegated_admin_account_id" {
  description = "Delegated administrator account ID."
  value       = module.delegated.delegated_admin_account_id
}

output "external_id" {
  description = "External ID to enter alongside the role ARNs."
  value       = module.management.external_id
}

output "relyance_org_scan_form" {
  description = "All org-scan values in one object, ready to transcribe into the Relyance UI."
  value = {
    external_id                = module.management.external_id
    org_reader_role_arn        = module.management.org_reader_role_arn
    discovery_role_arn         = module.delegated.discovery_role_arn
    org_view_arn               = module.delegated.org_view_arn
    scanner_role_name          = module.delegated.scanner_role_name
    delegated_admin_account_id = module.delegated.delegated_admin_account_id
  }
}
