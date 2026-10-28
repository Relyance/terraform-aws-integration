# Example: a single AWS account granting Relyance several integrations with
# per-service least-privilege roles. S3 is scoped to two buckets; DynamoDB to
# all tables; Redshift/CloudWatch metadata.

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "relyance" {
  source = "../.."

  # relyance_principal_arns defaults to the Relyance production principal --
  # leave it unset unless Relyance tells you otherwise.
  # external_id is auto-generated as a stable UUID; set it explicitly only if
  # Relyance gave you a specific value. The generated value is in the outputs.

  role_topology = "per_service" # or "shared"

  integrations = {
    aws_s3 = {
      resource_arns = [
        "arn:aws:s3:::acme-analytics",
        "arn:aws:s3:::acme-pii-store",
      ]
    }
    aws_dynamodb   = { all_resources = true } # explicit: all tables
    aws_redshift   = {}
    aws_cloudwatch = {}
    # Full-account inventory (the "aws" integration) is a separate advanced path --
    # it requires a Resource Explorer aggregator index + view first. See the README
    # "Resource Explorer preflight" section and the organization-full-inventory example.
  }

  tags = {
    ManagedBy = "terraform"
    Vendor    = "relyance"
  }
}

output "paste_into_relyance_ui" {
  value = module.relyance.relyance_form_values
}

output "external_id" {
  value = module.relyance.external_id
}
