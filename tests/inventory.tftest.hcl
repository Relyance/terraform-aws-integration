mock_provider "aws" {
  mock_resource "aws_iam_policy" {
    defaults = { arn = "arn:aws:iam::123456789012:policy/ExampleInventory" }
  }
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
}

mock_provider "random" {}

run "inventory_does_not_enable_content_scans" {
  command = plan
  variables {
    external_id  = "example-tenant-external-id"
    integrations = { aws = {} }
  }
  assert {
    condition     = toset(keys(module.role)) == toset(["Relyance-aws"])
    error_message = "Inventory must create only its inventory role."
  }
  assert {
    condition     = local.resolved_groups["aws"].managed_policy_arns == ["arn:aws:iam::aws:policy/SecurityAudit"]
    error_message = "Inventory must retain its reviewed SecurityAudit grant."
  }
  assert {
    condition     = !contains(flatten([for s in local.resolved_groups["aws"].statements : s.actions]), "s3:GetObject")
    error_message = "Inventory must not silently enable S3 object reads."
  }
}

run "trust_requires_the_customer_external_id" {
  command = plan
  module {
    source = "./modules/service-role"
  }
  variables {
    role_name               = "ExampleInventory"
    relyance_principal_arns = ["arn:aws:iam::123456789012:role/ExampleScanner"]
    external_id             = "example-tenant-external-id"
    policies                = {}
  }
  assert {
    condition = (
      one(one(data.aws_iam_policy_document.trust.statement).condition).test == "StringEquals" &&
      one(one(data.aws_iam_policy_document.trust.statement).condition).variable == "sts:ExternalId" &&
      toset(one(one(data.aws_iam_policy_document.trust.statement).condition).values) == toset(["example-tenant-external-id"])
    )
    error_message = "Role assumption must require the exact customer external ID."
  }
  assert {
    condition     = toset(one(one(data.aws_iam_policy_document.trust.statement).principals).identifiers) == toset(["arn:aws:iam::123456789012:role/ExampleScanner"])
    error_message = "The role must trust only the supplied scanner principal."
  }
}
