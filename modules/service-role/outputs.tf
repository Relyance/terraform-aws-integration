output "role_arn" {
  description = "ARN of the role Relyance assumes. Paste this into the Relyance integration form."
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the created role."
  value       = aws_iam_role.this.name
}

output "policy_arns" {
  description = "ARNs of the per-integration managed policies created for this role."
  value       = { for k, p in aws_iam_policy.group : k => p.arn }
}
