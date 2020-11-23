terraform {
  required_providers {
    commercetools = {
      source = "labd/commercetools"
    }
  }
}

data "aws_region" "current" {}