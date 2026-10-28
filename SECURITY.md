# Security model

This document is for the security/cloud team reviewing what access these modules
grant Relyance.

## Trust model

- **Cross-account IAM role assumption.** Customers do not create or share long-lived
  AWS access keys with Relyance. Access is via customer-created cross-account IAM
  roles, assumable only by the Relyance scanner principal (`relyance_principal_arns`,
  defaulting to the Relyance production principal) and protected by an External ID.
- **External ID (confused-deputy protection).** Every role trust policy requires
  `sts:ExternalId` to equal a per-tenant value; without it, assumption is denied.
  Relyance generates this value (unique per customer); paste it from the onboarding
  UI. If omitted, the module generates a stable random UUID as a fallback.
- **Single statement, gated condition.** The trust policy allows `sts:AssumeRole`
  and `sts:TagSession`, both under the External-ID condition.

## Least privilege

- **Read-only.** All granted actions are `Describe*`/`List*`/`Get*`/`Search` plus,
  where data inspection is in scope, object/item read (`s3:GetObject`,
  `dynamodb:Scan`/`Query`) and IAM-DB-auth read for RDS/Redshift. No create, update,
  or delete actions are granted by the default paths.
- **Redshift Data API caveat.** `redshift-data:ExecuteStatement` runs SQL and is not
  intrinsically read-only; it executes whatever the **mapped database user** may run.
  Read-only is enforced at the database layer — map Relyance to a Redshift user with
  only SELECT privileges. The IAM grant is the transport; the DB user's grants are
  the boundary.
- **Full-account inventory (`aws`)** attaches the AWS-managed **`SecurityAudit`**
  policy plus a short inline tail (15 actions AWS does not include in it, such as
  `resource-explorer-2:Search`, `glue:GetTable`, `lambda:GetFunction`, and
  `cloudwatch:GetMetricStatistics`). `SecurityAudit` is read-only — it grants only
  security-configuration metadata reads and no create/update/delete — but it is
  broader than the calls the scanner makes: it covers read-only metadata across
  roughly 200 services, not just the ~15 the inventory crawler touches. We accept
  that breadth here because AWS maintains the policy as services are added, which
  the previous 77-action inline list could not track. Per-service integration roles
  (`aws_s3`, `aws_dynamodb`, `aws_ses`, …) are unaffected and stay narrowly curated.
- **Organization scan (`modules/org-scan`)** uses the AWS-managed **`ReadOnlyAccess`**
  policy on the per-account scanner role (plus `tag:Get*` and Resource Explorer
  search), per Relyance's org-scan requirements. This is read-only but broader than
  the curated single-account per-service roles — it permits read of any service's
  metadata. The org reader and discovery roles remain narrowly scoped
  (organizations/Identity Center read; Resource Explorer query).
- **Generated, not hand-written.** The IAM actions are generated from Relyance's
  supported-connector permission catalog and reconciled at release time via
  `make generate-check`, which fails on drift. The committed, reviewable result is
  [`generated/permissions.json`](generated/permissions.json) — what you review,
  including any attached managed-policy ARNs, is exactly what is deployed.
- **Explicit scope for data stores.** `aws_s3` and `aws_dynamodb` require either an
  explicit `resource_arns` list or `all_resources = true`; broad access is never a
  silent default.
- **Resource scoping.** S3 statements are scoped to the bucket/object ARNs you
  provide; DynamoDB to the table ARNs you provide. Actions that AWS does not support
  resource-level scoping for use `Resource: "*"` (these are non-mutating metadata
  reads).

## Controls available to you

- **`permissions_boundary_arn`** — attach a permissions boundary to every created
  role (single-account and org, including the StackSet-deployed role).
- **`role_topology`** — `per_service` (one role per integration; revoke one by
  destroying one role) or `shared` (one role).
- **Partition-aware** — wildcard ARNs use the current AWS partition
  (`aws` / `aws-us-gov` / `aws-cn`).
- **Tagging** — all roles/policies are tagged via `tags`.

## What is NOT included

- No write/delete actions on the default paths. (Subject-rights / DSR flows that
  require write access are not enabled here.)
- No long-lived credentials, access keys, or users are created.
- RDS/Redshift data-plane requires you to separately provision network reachability
  and an IAM-auth database user — the module grants only the IAM side.

## Revocation

- Destroy the relevant role(s) with `terraform destroy`, or remove an integration
  key and re-apply. In `per_service` topology each integration is an independent role.
- Rotating the External ID: set a new `external_id` and re-apply.

## Reporting

For security concerns about these modules, contact your Relyance representative.
