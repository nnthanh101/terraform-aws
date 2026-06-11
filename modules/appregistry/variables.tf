# AppRegistry module variables.
# Count-guarded: servicecatalog-appregistry is not available in LocalStack Community edition.

variable "enable_appregistry" {
  type        = bool
  description = "Enable AWS AppRegistry application resource. Set false for LocalStack (Community edition does not emulate servicecatalog-appregistry)."
  default     = false
}

variable "application_name" {
  type        = string
  description = "AWS AppRegistry application name. Use a generic slug that identifies your platform (e.g. 'my-platform')."
  default     = "my-application"
}
