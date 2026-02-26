module "aws-iam-identity-center" {
  source = "../.." // local example

  // APRA CPS 234 + FOCUS 1.2+ required compliance tags applied to all taggable resources
  default_tags = {
    data_classification = "internal"
    x_cost_center       = "platform"
    x_project           = "iam-identity-center"
    x_environment       = "example"
    x_service_name      = "sso"
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