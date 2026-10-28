terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

# Trust policy: Relyance assumes this role only when presenting the per-tenant
# external ID. A single statement covers AssumeRole + TagSession, both gated on
# the external ID, so session tagging (if used) is also restricted to Relyance.
data "aws_iam_policy_document" "trust" {
  statement {
    sid     = "RelyanceAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "AWS"
      identifiers = var.relyance_principal_arns
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = var.role_name
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  permissions_boundary = var.permissions_boundary_arn
  max_session_duration = var.max_session_duration
  tags                 = var.tags
}

locals {
  # Groups that contribute inline statements (SES/SNS etc. may contribute only
  # managed_policy_arns and have no statements).
  statement_groups = { for k, v in var.policies : k => v if length(v.statements) > 0 }
}

data "aws_iam_policy_document" "group" {
  for_each = local.statement_groups

  dynamic "statement" {
    for_each = each.value.statements
    content {
      sid       = statement.value.sid
      effect    = "Allow"
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

# Customer-managed policy per group (default). Clean and individually auditable;
# one role carries one policy in per_service topology, well under the
# 10-managed-policy-per-role quota.
resource "aws_iam_policy" "group" {
  for_each = var.use_inline_policies ? {} : local.statement_groups

  name   = "${var.role_name}-${each.key}"
  policy = data.aws_iam_policy_document.group[each.key].json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "group" {
  for_each = aws_iam_policy.group

  role       = aws_iam_role.this.name
  policy_arn = each.value.arn
}

# Inline policy per group (shared topology). Inline policies do NOT count against
# the managed-policy-attachment quota, so one shared role can carry every
# integration's permissions without hitting the limit.
resource "aws_iam_role_policy" "group" {
  for_each = var.use_inline_policies ? local.statement_groups : {}

  name   = each.key
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.group[each.key].json
}

# AWS-managed policies requested by any group (used sparingly).
resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(flatten([for g in values(var.policies) : g.managed_policy_arns]))

  role       = aws_iam_role.this.name
  policy_arn = each.value
}
