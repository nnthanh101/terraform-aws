# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Derived from aws-samples/aws-transfer-family-terraform. See NOTICE.txt.

output "server_id" {
  description = "The ID of the transfer server"
  value       = aws_transfer_server.transfer_server.id
}

output "server_endpoint" {
  description = "The endpoint of the created Transfer Family server"
  value       = aws_transfer_server.transfer_server.endpoint
}
