# Changelog

## v1.2.0

Full-account inventory role now leans on an AWS-managed policy.

- **`aws` (full inventory): attach `arn:aws:iam::aws:policy/SecurityAudit`** and keep
  inline only the 15 actions it does not grant. The inline statement drops from 77
  actions to 15. Net access is equivalent-or-broader, never narrower: every removed
  action was verified against SecurityAudit policy version v91.
  - **Action required if you audit the role's inline policy:** the policy attached to
    the inventory role changes shape. No change is needed to your module inputs.
  - Rationale and the least-privilege trade-off are documented in
    [`SECURITY.md`](SECURITY.md#least-privilege). Per-service integration roles
    (`aws_s3`, `aws_dynamodb`, `aws_ses`, …) are unchanged and stay narrowly curated.
- The SDK now declares the SecurityAudit ARN as the base grant for the inventory,
  assets-discovery, and AI-discovery forms, listing only the uncovered actions
  individually (`relyance#25976` and predecessors). The generator consumes that
  declaration and cross-checks it against the curation in both directions, so a
  managed policy can neither appear in a customer role without review nor stay
  attached after the scanner stops needing it.
- No net change to what the scanner can read. Permissions the SDK previously spelled
  out individually — SageMaker reads, most Bedrock reads, ECS/EKS/EFS/autoscaling
  metadata, `iam:GetInstanceProfile` — are granted by SecurityAudit instead of inline.
- CI now gates the permission catalog on every PR: it fails if the committed catalog
  is hand-edited or if the SDK declares a permission the curation has not decided on.

## v1.1.0

Initial customer-preview release.

- Single-account module: per-integration or shared read-only roles, cross-account
  assume + External ID trust.
- Coverage: S3, DynamoDB, RDS, Redshift, CloudWatch, Glue, SES, SNS, X-Ray, and a
  full-account Resource Explorer inventory (incl. AI discovery). Metadata for all;
  data-plane read for S3, DynamoDB, RDS, Redshift.
- Organization-wide module (`modules/org-scan`): org-reader + Resource Explorer
  reader roles and a service-managed StackSet that deploys a read-only account-reader
  role org-wide.
- Safety/UX: explicit `resource_arns` / `all_resources` for S3 & DynamoDB (no silent
  broad access), blocking variable validation for unknown integration keys, merged
  trust statement, inline policies for shared topology (avoids the managed-policy
  quota), permissions-boundary support, partition-aware ARNs, auto-generated External
  ID with override.
- IAM actions generated from the supported-connector permission catalog with
  drift detection; committed as `generated/permissions.json`.
