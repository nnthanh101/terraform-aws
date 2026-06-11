# Foundation module variables.

variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod, sandbox, dr)."
}

variable "name_prefix" {
  type        = string
  description = "Prefix for resource naming (e.g. application slug)."
  default     = "app"
}

variable "secret_recovery_window" {
  type        = number
  description = "Recovery window in days for Secrets Manager secrets on destroy. 0 = instant delete (local/dev). Set >= 7 for prod-path environments."
  default     = 0
}

variable "additional_tags" {
  type        = map(string)
  default     = {}
  description = "Extra tags merged onto every resource (e.g. awsApplication for AppRegistry myApplications)."
}
