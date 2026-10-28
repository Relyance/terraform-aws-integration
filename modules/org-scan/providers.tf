terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
      # The org module spans two accounts. The caller passes:
      #   aws.management -> the Organizations management account (org listing + StackSet)
      #   aws.delegated  -> the account holding the Resource Explorer AGGREGATOR view
      # (these may be the same account; pass the same provider twice if so).
      configuration_aliases = [aws.management, aws.delegated]
    }
  }
}
