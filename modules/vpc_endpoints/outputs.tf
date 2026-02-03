output "s3_endpoint_id" {
  value = aws_vpc_endpoint.s3.id
}

output "endpoint_ids" {
  description = "List of Interface VPC endpoint IDs"
  value = [for ep in aws_vpc_endpoint.interface : ep.id]
}