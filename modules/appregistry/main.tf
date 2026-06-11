# AppRegistry module — count-guarded for LocalStack compatibility.
# servicecatalog-appregistry is NOT in LocalStack Community edition.
# Guard: var.enable_appregistry = false (local) → count = 0 → no API call.
#        var.enable_appregistry = true  (dev/prod) → count = 1 → real AppRegistry resource.
# Ref: https://aws.amazon.com/blogs/mt/tag-your-aws-resources-for-cost-allocation-with-aws-myapplications/

resource "aws_servicecatalogappregistry_application" "this" {
  count = var.enable_appregistry ? 1 : 0

  name        = var.application_name
  description = "Platform application managed by Terraform."
}
