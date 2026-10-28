variable "relyance_principal_arns" {
  description = "Relyance scanner principal ARN(s). All org roles trust this directly + the external ID (single-hop assume, no role chaining). Defaults to the Relyance production principal; override only if instructed."
  type        = list(string)
  default     = ["arn:aws:iam::580082088342:user/tenant-prod-access"]
}

variable "external_id" {
  description = "Per-tenant external ID enforced on every AssumeRole (confused-deputy protection). Leave null to auto-generate a stable UUID; set explicitly to use a Relyance-provided value."
  type        = string
  default     = null
}

# --- Role names (match the Relyance org-scan requirements) ---

variable "org_reader_role_name" {
  description = "Org-mapping role created in the management account."
  type        = string
  default     = "OrgReaderRole"
}

variable "discovery_role_name" {
  description = "Resource Explorer query role created in the delegated administrator account."
  type        = string
  default     = "DiscoveryRole"
}

variable "scanner_role_name" {
  description = "Read-only resource-scanner role deployed into every member account (and the management account). Must be identical everywhere -- the scanner builds arn:aws:iam::<account-id>:role/<this-name>."
  type        = string
  default     = "GlobalResourceScannerRole"
}

variable "org_view_name" {
  description = "Name of the organization-wide Resource Explorer view created in the delegated administrator account."
  type        = string
  default     = "RelyanceOrgView"
}

# --- Resource Explorer ---

variable "register_resource_explorer_delegated_admin" {
  description = "Register the delegated (DA) account as the Resource Explorer delegated administrator for the org (run from the management account). Set false if already registered."
  type        = bool
  default     = true
}

variable "register_stacksets_delegated_admin" {
  description = "Register the DA account as a CloudFormation StackSets delegated administrator (required to run the service-managed StackSet from the DA). Set false if already registered."
  type        = bool
  default     = true
}

variable "create_resource_explorer" {
  description = <<-EOT
    Create the Resource Explorer footprint: aggregator index + org view in the DA,
    a local index in the management account, and local indexes in every member
    account/Region (via StackSet). Set false to reuse an existing setup and supply
    existing_org_view_arn.
  EOT
  type        = bool
  default     = true
}

variable "existing_org_view_arn" {
  description = "Existing org-wide Resource Explorer view ARN, used when create_resource_explorer = false."
  type        = string
  default     = null
}

variable "index_regions" {
  description = <<-EOT
    Regions in which to enable a LOCAL Resource Explorer index in every account.
    The aggregator only rolls up Regions that have a local index, so list every
    Region you want discovered. Defaults to [home_region].
  EOT
  type        = list(string)
  default     = []
}

variable "home_region" {
  description = "Region for the aggregator index, org view, and the StackSet instances."
  type        = string
  default     = "us-east-1"
}

# --- Deployment scope ---

variable "target_organizational_unit_ids" {
  description = "OU IDs to deploy the scanner role / local indexes into. Empty = the entire org (root)."
  type        = list(string)
  default     = []
}

variable "include_management_account" {
  description = "Also create the scanner role + a local index in the management account (service-managed StackSets do not target the management account)."
  type        = bool
  default     = true
}

variable "permissions_boundary_arn" {
  description = "Optional permissions boundary applied to every created role (including the StackSet-deployed scanner role)."
  type        = string
  default     = null
}

variable "max_session_duration" {
  description = "Max STS session duration (seconds) for the created roles."
  type        = number
  default     = 3600
}

variable "tags" {
  description = "Tags applied to created roles, indexes, view, and StackSets."
  type        = map(string)
  default     = {}
}

variable "name_prefix" {
  description = "Optional prefix applied to every created resource name across both halves."
  type        = string
  default     = ""
}

variable "name_suffix" {
  description = "Optional suffix applied to every created resource name across both halves."
  type        = string
  default     = ""
}
