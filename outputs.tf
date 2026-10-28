output "role_arns" {
  description = "Created role name => ARN."
  value       = { for name, m in module.role : name => m.role_arn }
}

output "relyance_form_values" {
  description = <<-EOT
    What to enter into each enabled Relyance integration form: integration key =>
    { role_arn, external_id }. In per_service topology each integration has its own
    role; in shared topology they all point at the single shared role.
  EOT
  value = {
    for k in keys(local.enabled) : k => {
      role_arn = (
        var.role_topology == "shared"
        ? module.role[var.shared_role_name].role_arn
        : module.role["${var.role_name_prefix}-${k}"].role_arn
      )
      external_id = local.external_id
    }
  }
}

output "external_id" {
  description = "The external ID (auto-generated if not supplied) to enter alongside the role ARN in each form."
  value       = local.external_id
}
