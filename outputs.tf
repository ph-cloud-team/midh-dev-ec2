############################################
# Terraform Outputs for AWX and Operations
############################################

output "instance_id" {
  description = "EC2 instance ID consumed by AWX and operational workflows."
  value       = module.ec2_instance.instance_id
}

output "private_ip" {
  description = "Private IP address consumed by AWX inventory sync."
  value       = module.ec2_instance.private_ip
}

output "hostname" {
  description = "Hostname value used by AWX inventory sync."
  value       = module.ec2_instance.private_ip
}

output "environment" {
  description = "Environment metadata consumed by AWX inventory sync."
  value       = var.environment
}

output "application" {
  description = "Application metadata consumed by AWX inventory sync."
  value       = var.application
}

output "owner" {
  description = "Owner metadata consumed by AWX inventory sync."
  value       = var.owner
}

output "security_group_id" {
  description = "Module-managed EC2 security group ID."
  value       = module.ec2_instance.security_group_id
}

output "iam_role_name" {
  description = "Module-managed EC2 IAM role name."
  value       = module.ec2_instance.iam_role_name
}

output "ssm_transfer_bucket_name" {
  description = "Dedicated S3 bucket used by AWX SSM module transfer."
  value       = module.ssm_transfer_bucket.bucket_id
}

output "ssm_transfer_bucket_arn" {
  description = "ARN of the dedicated S3 bucket used by AWX SSM module transfer."
  value       = module.ssm_transfer_bucket.bucket_arn
}

output "ssm_transfer_bucket_kms_key_arn" {
  description = "KMS key ARN used to encrypt the AWX SSM transfer bucket."
  value       = module.ssm_transfer_bucket.kms_key_arn
}

output "s3_gateway_endpoint_id" {
  description = "S3 Gateway VPC endpoint ID used by private EC2 instances for AWX SSM module transfer."
  value       = module.vpc_endpoints.endpoint_ids["s3"]
}

output "ssm_endpoint_id" {
  description = "SSM Interface VPC endpoint ID."
  value       = module.vpc_endpoints.endpoint_ids["ssm"]
}

output "ssmmessages_endpoint_id" {
  description = "SSM Messages Interface VPC endpoint ID."
  value       = module.vpc_endpoints.endpoint_ids["ssmmessages"]
}

output "ec2messages_endpoint_id" {
  description = "EC2 Messages Interface VPC endpoint ID."
  value       = module.vpc_endpoints.endpoint_ids["ec2messages"]
}

output "interface_endpoint_security_group_id" {
  description = "Security group ID attached to SSM Interface VPC endpoints."
  value       = module.vpc_endpoints.interface_endpoint_security_group_id
}

output "private_route_table_id" {
  description = "Private subnet route table associated with the S3 Gateway VPC endpoint."
  value       = data.aws_route_table.private.id
}
