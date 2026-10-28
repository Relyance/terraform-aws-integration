variable "relyance_principal_arns" {
  description = <<-EOT
    Relyance scanner principal ARN(s) allowed to assume the created role(s).
    Defaults to the Relyance PRODUCTION principal; override for test/staging.
  EOT
  type        = list(string)
  default     = ["arn:aws:iam::580082088342:user/tenant-prod-access"]
}

variable "external_id" {
  description = <<-EOT
    Per-tenant external ID enforced on every AssumeRole. Leave null (default) to
    auto-generate a stable random UUID that persists in state; set explicitly to
    use a value Relyance provided or to bring your own.
  EOT
  type        = string
  default     = null
}

variable "role_topology" {
  description = <<-EOT
    "per_service" -> one least-privilege role per enabled integration (recommended;
    maps 1:1 to each Relyance integration form, finest blast-radius control).
    "shared"      -> a single role carrying one inline policy per enabled integration;
    paste the same ARN into every integration form (simplest for the customer).
  EOT
  type        = string
  default     = "per_service"

  validation {
    condition     = contains(["per_service", "shared"], var.role_topology)
    error_message = "role_topology must be \"per_service\" or \"shared\"."
  }
}

variable "role_name_prefix" {
  description = "Prefix for per-service role names (per_service topology). Role => <prefix>-<integration>."
  type        = string
  default     = "Relyance"
}

variable "shared_role_name" {
  description = "Role name when role_topology = \"shared\"."
  type        = string
  default     = "RelyanceScanner"
}

variable "integrations" {
  description = <<-EOT
    Which AWS integrations to enable and how to scope them. Keys must match the
    generated catalog (aws_s3, aws_dynamodb, aws_redshift, aws_rds, aws_cloudwatch,
    aws_glue, aws_ses, aws_sns, aws_xray, aws).

    Scoping (aws_s3 and aws_dynamodb support resource-level scoping):
      * resource_arns -> grant only these bucket/table ARNs.
      * all_resources = true -> explicitly grant ALL buckets/tables ("*").
      * For aws_s3 / aws_dynamodb you MUST set one or the other -- broad access is
        never the silent default.
      * Other integrations' API calls aren't resource-scopable in IAM, so their
        Resource is always "*"; resource_arns / all_resources are ignored for them.
  EOT
  type = map(object({
    enabled       = optional(bool, true)
    resource_arns = optional(list(string), [])
    all_resources = optional(bool, false)
  }))
  default = {}

  validation {
    condition = length(setsubtract(keys(var.integrations), [
      "aws_s3", "aws_dynamodb", "aws_redshift", "aws_rds", "aws_cloudwatch",
      "aws_glue", "aws_ses", "aws_sns", "aws_xray", "aws",
    ])) == 0
    error_message = "Unknown integration key. Supported keys: aws_s3, aws_dynamodb, aws_redshift, aws_rds, aws_cloudwatch, aws_glue, aws_ses, aws_sns, aws_xray, aws."
  }

  validation {
    condition = alltrue([
      for k, v in var.integrations :
      !contains(["aws_s3", "aws_dynamodb"], k)
      || !v.enabled
      || v.all_resources
      || length(v.resource_arns) > 0
    ])
    error_message = "Enabled aws_s3 and aws_dynamodb integrations require either resource_arns = [...] or all_resources = true (broad access must be explicit)."
  }
}

variable "permissions_boundary_arn" {
  description = "Optional permissions boundary applied to every created role."
  type        = string
  default     = null
}

variable "max_session_duration" {
  description = "Max STS session duration (seconds) for created roles."
  type        = number
  default     = 3600
}

variable "tags" {
  description = "Tags applied to all created roles and policies."
  type        = map(string)
  default     = {}
}
