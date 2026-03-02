# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Derived from terraform-aws-modules/terraform-aws-ecs v7.3.1 (Apache-2.0). See NOTICE.

output "wrapper" {
  description = "Map of outputs of a wrapper."
  value       = module.wrapper
  # sensitive = false # No sensitive module output found
}
