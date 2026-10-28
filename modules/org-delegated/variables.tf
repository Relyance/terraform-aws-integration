variable "relyance_principal_arns" {
  description = "Relyance scanner principal ARN(s). Defaults to the Relyance production principal; override only if instructed."
  type        = list(string)
  default     = ["arn:aws:iam::580082088342:user/tenant-prod-access"]
}

variable "external_id" {
  description = "Per-tenant external ID -- MUST match the value from the org-management module (use its external_id output)."
  type        = string
}

variable "organization_id" {
  description = "AWS Organization ID (from org-management's organization_id output). Used to scope the org view."
  type        = string
}

variable "management_account_id" {
  description = "Organization management account ID (from org-management). Used to build the org-view scope ARN."
  type        = string
}

variable "organization_root_id" {
  description = "Organization root ID (from org-management). StackSet deployment target unless target_organizational_unit_ids is set."
  type        = string
  default     = null
}

variable "target_organizational_unit_ids" {
  description = "OU IDs to deploy into. Empty = the entire org (uses organization_root_id)."
  type        = list(string)
  default     = []
}

variable "discovery_role_name" {
  description = "Resource Explorer query role created in this (DA) account."
  type        = string
  default     = "DiscoveryRole"
}

variable "scanner_role_name" {
  description = "Read-only scanner role deployed into every member account via StackSet. Must match the management module's scanner_role_name."
  type        = string
  default     = "GlobalResourceScannerRole"
}

variable "org_view_name" {
  description = "Name of the organization-wide Resource Explorer view."
  type        = string
  default     = "RelyanceOrgView"
}

variable "create_resource_explorer" {
  description = "Create the aggregator index, org view, and per-Region local-index StackSet. Set false to reuse existing RE setup (supply existing_org_view_arn)."
  type        = bool
  default     = true
}

variable "existing_org_view_arn" {
  description = "Existing org-wide Resource Explorer view ARN, used when create_resource_explorer = false."
  type        = string
  default     = null
}

variable "index_regions" {
  description = "Regions in which to enable a LOCAL Resource Explorer index in every account. Defaults to [home_region]. The aggregator only rolls up Regions that have a local index."
  type        = list(string)
  default     = []
}

variable "home_region" {
  description = "Region for the aggregator index, org view, and StackSet instances."
  type        = string
  default     = "us-east-1"
}

variable "permissions_boundary_arn" {
  description = "Optional permissions boundary applied to the DiscoveryRole and the StackSet-deployed scanner role."
  type        = string
  default     = null
}

variable "max_session_duration" {
  description = "Max STS session duration (seconds) for created roles."
  type        = number
  default     = 3600
}

variable "tags" {
  description = "Tags applied to created roles, indexes, view, and StackSets."
  type        = map(string)
  default     = {}
}

variable "name_prefix" {
  description = "Optional prefix applied to every created resource name. Must match the management module's value."
  type        = string
  default     = ""
}

variable "name_suffix" {
  description = "Optional suffix applied to every created resource name. Must match the management module's value."
  type        = string
  default     = ""
}
