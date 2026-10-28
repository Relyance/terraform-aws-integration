variable "role_name" {
  description = "Name of the IAM role the customer creates for Relyance to assume."
  type        = string
}

variable "relyance_principal_arns" {
  description = <<-EOT
    Principal ARN(s) that Relyance assumes the role from. Provided by Relyance
    (the scanner's source identity). Becomes the Principal in the trust policy.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.relyance_principal_arns) > 0
    error_message = "At least one Relyance principal ARN is required."
  }
}

variable "external_id" {
  description = "Per-tenant external ID enforced on sts:AssumeRole (provided by Relyance). Prevents the confused-deputy problem."
  type        = string

  validation {
    condition     = length(var.external_id) > 0
    error_message = "external_id must not be empty -- it is the confused-deputy guard."
  }
}

variable "permissions_boundary_arn" {
  description = "Optional permissions boundary to cap the role's effective permissions."
  type        = string
  default     = null
}

variable "max_session_duration" {
  description = "Max STS session duration (seconds). SDK requests 3600; allow override."
  type        = number
  default     = 3600
}

variable "policies" {
  description = <<-EOT
    Map of integration-key => policy group. Each group becomes one customer-managed
    policy attached to the role (one policy per integration keeps each well under the
    6,144-char managed-policy limit, even when many integrations share a single role).

    Each statement's `resources` is already fully resolved by the caller.
  EOT
  type = map(object({
    statements = list(object({
      sid       = string
      actions   = list(string)
      resources = list(string)
    }))
    managed_policy_arns = optional(list(string), [])
  }))
}

variable "use_inline_policies" {
  description = <<-EOT
    When true, attach each group's permissions as an inline role policy instead of a
    customer-managed policy. Inline policies don't count against the 10-managed-policy
    per-role quota, so a single role can carry many integrations (shared topology).
  EOT
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to the role and policies."
  type        = map(string)
  default     = {}
}
