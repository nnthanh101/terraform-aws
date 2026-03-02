# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Derived from terraform-aws-modules/terraform-aws-ecs v7.3.1 (Apache-2.0). See NOTICE.

variable "write_container_definition_to_file" {
  description = "Determines whether the container definition JSON should be written to a file. Used for debugging and checking diffs"
  type        = bool
  default     = true
}
