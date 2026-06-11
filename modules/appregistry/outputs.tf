# application_tag: merged at RESOURCE level via additional_tags input; NOT provider.default_tags
# (provider config is evaluated statically at plan time — using a module output there creates a cycle).
# Pattern in consuming root: additional_tags = try(module.appregistry.application_tag, {})
# Returns {} when enable_appregistry = false (LocalStack / bootstrap) — merge() is a no-op.

output "application_tag" {
  description = "AppRegistry awsApplication tag map. Empty when enable_appregistry=false."
  value       = var.enable_appregistry ? { awsApplication = aws_servicecatalogappregistry_application.this[0].application_tag } : {}
}
