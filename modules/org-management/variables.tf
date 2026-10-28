variable "relyance_principal_arns" {
  description = "Relyance scanner principal ARN(s). Defaults to the Relyance production principal; override only if instructed."
  type        = list(string)
  default     = ["arn:aws:iam::580082088342:user/tenant-prod-access"]
}

variable "external_id" {
  description = "Per-tenant external ID enforced on every AssumeRole. Leave null to auto-generate a stable UUID (output for use by the delegated module); set explicitly to use a Relyance-provided value."
  type        = string
  default     = null
}

variable "delegated_admin_account_id" {
  description = "Account ID of the delegated administrator (DA) account that will host Resource Explorer + StackSets."
  type        = string
}

variable "org_reader_role_name" {
  description = "Org-mapping role created in this (management) account."
  type        = string
  default     = "OrgReaderRole"
}

variable "scanner_role_name" {
  description = "Read-only resource-scanner role name (deployed org-wide by the delegated module; created here for the management account itself)."
  type        = string
  default     = "GlobalResourceScannerRole"
}

variable "register_resource_explorer_delegated_admin" {
  description = "Register the DA account as the Resource Explorer delegated administrator for the org. Set false if already registered."
  type        = bool
  default     = true
}

variable "register_stacksets_delegated_admin" {
  description = "Register the DA account as a CloudFormation StackSets delegated administrator. Set false if already registered."
  type        = bool
  default     = true
}

variable "include_management_account" {
  description = "Create the scanner role (+ optional local Resource Explorer index) in the management account, so it is scanned too."
  type        = bool
  default     = true
}

variable "create_management_local_index" {
  description = "Create a LOCAL Resource Explorer index in the management account (home Region) so its resources roll up into the org aggregator."
  type        = bool
  default     = true
}

variable "permissions_boundary_arn" {
  description = "Optional permissions boundary applied to created roles."
  type        = string
  default     = null
}

variable "max_session_duration" {
  description = "Max STS session duration (seconds) for created roles."
  type        = number
  default     = 3600
}

variable "tags" {
  description = "Tags applied to created roles and indexes."
  type        = map(string)
  default     = {}
}

variable "name_prefix" {
  description = "Optional prefix applied to every created resource name (roles, indexes, view, StackSets)."
  type        = string
  default     = ""
}

variable "name_suffix" {
  description = "Optional suffix applied to every created resource name. Useful for a non-colliding parallel/test deployment alongside existing roles."
  type        = string
  default     = ""
}
