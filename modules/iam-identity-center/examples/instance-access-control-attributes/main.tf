# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Derived from aws-ia/terraform-aws-iam-identity-center v1.0.4 (Apache-2.0). See NOTICE.

module "aws-iam-identity-center" {
  source = "../.." // local example

  // Canonical tags: enterprise + FOCUS (via Cost Allocation Tags) + CPS 234
  default_tags = {
    CostCenter         = "platform"
    Project            = "iam-identity-center"
    Environment        = "example"
    ServiceName        = "sso"
    DataClassification = "internal"
  }

  //Create desired access control attributes
  sso_instance_access_control_attributes = [
    {
      attribute_name = "FirstName"
      source         = ["$${path:name.givenName}"]
    },
    {
      attribute_name = "LastName"
      source         = ["$${path:name.familyName}"]
    }
  ]
}