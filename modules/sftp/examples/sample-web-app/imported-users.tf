# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Derived from aws-samples/aws-transfer-family-terraform. See NOTICE.txt.

# User Configuration
# NOTE: - Users must already exist in IAM Identity Center before adding them here
#       - access_grants can be given through groups only instead of each individual user
# Uncomment and customize the users below as needed

locals {
  imported_users = {
    # Uncomment and modify the examples below to add users:

    # "admin" = {
    #   user_name = "admin"
    #   access_grants = [
    #     {
    #       s3_path    = "/*"
    #       permission = "READWRITE"
    #     }
    #   ]
    # },

    # "analyst" = {
    #   user_name = "analyst"
    #   access_grants = [
    #     {
    #       s3_path    = "/*"
    #       permission = "READ"
    #     }
    #   ]
    # },

    # "developer" = {
    #   user_name = "developer"
    #   access_grants = [
    #     {
    #       s3_path    = "/*"
    #       permission = "WRITE"
    #     }
    #   ]
    # }
  }
}
