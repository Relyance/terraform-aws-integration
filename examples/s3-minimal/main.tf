# Golden path: a single account granting Relyance read access to ONE S3 bucket.
# Start here, verify the integration in the Relyance UI, then expand scope.

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

module "relyance_aws" {
  source = "../.."

  # relyance_principal_arns defaults to the Relyance production principal.
  # external_id auto-generates a stable UUID (returned below); override only if
  # Relyance gave you a specific value.

  integrations = {
    aws_s3 = {
      resource_arns = ["arn:aws:s3:::my-bucket"] # replace with your bucket(s)
    }
  }

  tags = {
    ManagedBy = "terraform"
    Vendor    = "relyance"
  }
}

# Enter these into the Relyance integration form (role ARN + external ID per integration):
output "relyance_setup_values" {
  value = module.relyance_aws.relyance_form_values
}
