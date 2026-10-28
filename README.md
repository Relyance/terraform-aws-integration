# Relyance AWS Integration — Terraform Modules

Terraform that grants Relyance the **least-privilege, read-only, cross-account**
IAM access needed to run Relyance AWS integrations.

Every integration authenticates the same way: **cross-account `sts:AssumeRole`
gated on a per-tenant External ID**. You create a role that trusts the Relyance
scanner principal, restricted by an External ID, carrying a read-only policy scoped
to exactly what the integration needs. This module creates those roles/policies and
outputs the values to enter into each integration form in the Relyance UI.

> This is a customer-preview module. The default path is intentionally narrow:
> start with one account and one integration, verify role assumption in the Relyance
> UI, then widen scope. Organization-wide setup is supported and documented under
> [Organization-wide setup](#organization-wide-setup-advanced) — we usually enable it
> alongside Relyance onboarding support.

## Quick start: cloud inventory in one account

```hcl
module "relyance_aws" {
  # Public Terraform and OpenTofu registries:
  source  = "Relyance/integration/aws"
  version = "1.2.0"

  # external_id: paste the value Relyance provides in the onboarding UI.
  external_id = "rel_ext_..." # see "External ID" below

  # Inventory metadata only. Data-content integrations remain opt-in.
  integrations = { aws = {} }

  tags = {
    ManagedBy = "terraform"
    Vendor    = "relyance"
  }
}

output "relyance_setup_values" {
  value = module.relyance_aws.relyance_form_values
}
```

```bash
terraform init
terraform plan
terraform apply
terraform output -json relyance_setup_values
```

`relyance_setup_values` returns, per enabled integration, the values to enter into
the Relyance UI:

```json
{
  "aws_s3": {
    "role_arn":    "arn:aws:iam::123456789012:role/Relyance-aws_s3",
    "external_id": "3f2a…"
  }
}
```

## Optional data-content integrations and resource scoping

For the resource-scopable integrations (`aws_s3`, `aws_dynamodb`) you must be
explicit — broad access is never the silent default:

```hcl
integrations = {
  aws_s3       = { resource_arns = ["arn:aws:s3:::bucket-a", "arn:aws:s3:::bucket-b"] }
  aws_dynamodb = { all_resources = true }  # explicitly grant all tables
}
```

Setting neither `resource_arns` nor `all_resources` for `aws_s3`/`aws_dynamodb`
fails validation. Other integrations' API calls aren't resource-scopable in IAM, so
their `Resource` is always `*`.

## Role topology

- **`per_service`** (default, recommended): one role per integration. Maps 1:1 to
  each Relyance form, gives the finest blast-radius control, and lets you revoke a
  single integration by destroying one role.
- **`shared`**: a single role carrying one inline policy per enabled integration —
  enter the same role ARN into every form. Simpler to manage, broader privilege.

`relyance_setup_values` returns the correct role ARN per integration for whichever
topology you choose.

## External ID

The External ID protects against the confused-deputy problem. **Use the value
Relyance generates for your tenant** (shown in the onboarding UI) — Relyance
controls it so it's unique per customer:

```hcl
external_id = "rel_ext_..." # from the Relyance UI
```

If you omit `external_id`, the module generates a stable random UUID and returns it
in `relyance_setup_values` for you to paste back into Relyance. Prefer the
Relyance-provided value.

## Coverage

Read-only metadata for every supported integration, plus **data-plane** read for
S3, DynamoDB, RDS, and Redshift:

| Integration | Key | Coverage |
|---|---|---|
| S3 | `aws_s3` | bucket metadata + object read (`s3:GetObject`) |
| DynamoDB | `aws_dynamodb` | table metadata + item read (`Scan`/`Query`) |
| Redshift | `aws_redshift` | cluster metadata + selected Redshift Data API query calls (IAM DB auth); read-only behavior is enforced by the mapped database user's grants (see note) |
| RDS | `aws_rds` | instance metadata + `rds-db:connect` (IAM DB auth) |
| CloudWatch | `aws_cloudwatch` | metric metadata |
| Glue | `aws_glue` | Data Catalog read |
| SES | `aws_ses` | identity / template read (explicit actions) |
| SNS | `aws_sns` | topic / subscription read (explicit actions) |
| X-Ray | `aws_xray` | trace summaries / service graph |
| Full inventory | `aws` | multi-service Resource Explorer metadata sweep + AI discovery (AWS-managed `SecurityAudit` + a 15-action tail) |

The exact IAM actions each integration grants are in
[`generated/permissions.json`](generated/permissions.json) — review it to see
precisely what access is requested.

### Data-plane prerequisites (RDS / Redshift)

RDS and Redshift data-plane read use **IAM database authentication — no Lambda**.
Two things are outside IAM/Terraform and are your responsibility:

- **Network reachability** from the Relyance scanner to the DB/cluster endpoint
  (VPC peering, PrivateLink, or a reachable endpoint).
- A **database user enabled for IAM authentication** (`rds_iam` /
  `AWSAuthenticationPlugin` for RDS; an IAM-mapped Redshift user) with the read
  grants the scan needs.

`rds-db:connect`, the selected Redshift Data API actions, and
`GetClusterCredentialsWithIAM` have a `*` resource scope today and can be
tightened to specific dbuser / cluster ARNs.

> **On "read-only":** `redshift-data:ExecuteStatement` is the Redshift Data API call
> for running SQL and is not intrinsically read-only — it executes whatever the
> mapped database user is allowed to run. Read-only scanning is enforced at the
> **database** layer: map Relyance to a Redshift user that has only read (SELECT)
> privileges. The IAM grant is the transport; the DB user's grants are the boundary.

## Resource Explorer preflight (`aws` full inventory)

The `aws` full-inventory integration uses AWS Resource Explorer to discover
resources. Before enabling it, confirm:

- [ ] Resource Explorer is enabled with an **aggregator index** in your chosen Region.
- [ ] A **local index** exists in every Region you want covered (the aggregator only
      rolls up Regions that have a local index).
- [ ] A Resource Explorer **view** exists (its ARN goes into the Relyance form).

(The org module can create the aggregator index + view for you — see below.)

## Organization-wide setup (advanced)

For org-wide discovery across many accounts, use the `org-scan` submodule (see
[`examples/organization-full-inventory/`](examples/organization-full-inventory/)).
Via the registry, submodules are addressed with `//`:

```hcl
module "relyance_org" {
  source  = "Relyance/integration/aws//modules/org-scan"
  version = "1.2.0"

  providers = {
    aws.management = aws.management
    aws.delegated  = aws.delegated
  }
  # ...
}
```

(For separate-team applies, use `//modules/org-management` and
`//modules/org-delegated` instead — see the `organization-split` example.)

It follows the AWS-recommended **delegated-administrator (DA)** model: the
management account stays low-traffic, and a member DA account is the operational
hub for Resource Explorer and StackSets. Provide credentials for both the
management and DA accounts (two provider aliases). Outputs map 1:1 to the Relyance
"Organization Scan" form:

| Created | Where | Form field |
|---|---|---|
| `OrgReaderRole` (org + Identity Center read) | management account | `org_reader_role_arn` |
| `DiscoveryRole` (Resource Explorer query) | delegated admin account | `discovery_role_arn` |
| RE delegated-admin registration, aggregator index, org view (`RelyanceOrgView`) | mgmt + DA | `org_view_arn` |
| `GlobalResourceScannerRole` (AWS-managed **ReadOnlyAccess** + `tag:GetTagKeys` / `tag:GetTagValues` / `tag:GetResources`) via service-managed StackSet (auto-deploy) + the management account | every account | `scanner_role_name`, `delegated_admin_account_id` |
| Local Resource Explorer index per Region | every account (StackSet) + management | enables org-wide search |

All roles trust the Relyance principal + External ID directly (single-hop assume,
no role chaining). The member scanner role uses the AWS-managed `ReadOnlyAccess`
policy (per Relyance's org-scan requirements) — broader than the single-account
per-service roles, scoped to read-only.

**Org preflight:**

- [ ] Provide **management-account** and **delegated-admin (DA)** credentials
      (the `aws.management` and `aws.delegated` providers).
- [ ] Enable **trusted access** with AWS Organizations for CloudFormation StackSets
      and Resource Explorer (one-time; e.g. `aws organizations enable-aws-service-access`).
      The module registers the DA for both (toggle off if already registered).
- [ ] Choose `index_regions` — every Region you want a local index (and therefore
      discovery) in. The aggregator only rolls up Regions that have a local index.
- [ ] One Resource Explorer aggregator is allowed per org; if you already have RE
      configured, set `create_resource_explorer = false` and pass `existing_org_view_arn`.

We recommend running org setup with Relyance onboarding support.

## How permissions are kept honest

Every inline IAM action is generated from Relyance's supported-connector permission
catalog and reconciled at release time via `make generate-check`, which fails on any
drift (an action the scanner needs that isn't accounted for). The committed,
human-readable result is
[`generated/permissions.json`](generated/permissions.json), which these modules
consume directly — so what you review is exactly what is deployed.

For the per-service integrations, granted actions equal what the scanner calls. Two
paths deliberately use AWS-managed policies instead, and there the grant is broader
than the call set: the `aws` full-inventory role attaches `SecurityAudit`, and
`modules/org-scan` attaches `ReadOnlyAccess`. Both are read-only. See
[`SECURITY.md`](SECURITY.md#least-privilege) for why, and for what stays narrow.

## Layout

```
main.tf / variables.tf / outputs.tf   # single-account composition (start here)
modules/service-role/                 # trust policy + per-integration read policies
modules/org-scan/                     # organization-wide: reader roles + StackSet
generated/permissions.json            # the exact IAM actions each integration grants
examples/s3-minimal/                  # golden path: one account, one bucket
examples/single-account-multi-service/# several integrations in one account (advanced)
examples/organization-full-inventory/ # org-wide setup (advanced)
```

## Requirements

- Terraform >= 1.5
- AWS provider >= 5.0
- `random` provider >= 3.0 (external-ID generation)

## Terraform and OpenTofu

The same module works with Terraform and OpenTofu. Public CI validates the module,
examples and inventory plan tests with both CLIs. Use the matching `init`, `plan`
and `apply` commands. Review the plan before applying IAM changes.

Existing installations may continue using the original
`assets.relyance.ai/relyance/integration/aws` address. When changing the
source of an existing module, retain its module block name, inputs and version,
then review the plan; changing the source does not require renaming resources.

## License and releases

[MPL-2.0](LICENSE). Releases are immutable; fixes receive a new version.
`PUBLIC_RELEASE.json` records the reviewed source revision and exported file hashes.

Report issues in this public repository. Permission catalogs are generated and
reviewed upstream; edits to generated JSON alone are not a supported update path.
