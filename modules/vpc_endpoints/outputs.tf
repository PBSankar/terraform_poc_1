output "s3_endpoint_id" {
  description = "S3 Gateway VPC endpoint ID"
  value       = aws_vpc_endpoint.s3.id
}

output "dynamodb_endpoint_id" {
  description = "DynamoDB Gateway VPC endpoint ID"
  value       = aws_vpc_endpoint.dynamodb.id
}

output "interface_endpoint_ids" {
  description = "Map of Interface VPC endpoint IDs"
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.id }
}