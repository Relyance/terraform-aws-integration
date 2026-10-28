output "external_id" {
  description = "External ID (auto-generated if not supplied). Pass this to the org-delegated module."
  value       = local.external_id
}

output "organization_id" {
  description = "AWS Organization ID. Pass to the org-delegated module (org view scope)."
  value       = data.aws_organizations_organization.this.id
}

output "management_account_id" {
  description = "Organization management account ID. Pass to the org-delegated module (org view scope)."
  value       = data.aws_organizations_organization.this.master_account_id
}

output "organization_root_id" {
  description = "Organization root ID. Pass to the org-delegated module (StackSet deployment target) unless scoping to specific OUs."
  value       = data.aws_organizations_organization.this.roots[0].id
}

output "org_reader_role_arn" {
  description = "OrgReaderRole ARN -- the \"Organization Reader Role ARN\" form field."
  value       = module.org_reader.role_arn
}

output "scanner_role_name" {
  description = "GlobalResourceScannerRole name."
  value       = local.scanner_name
}
