############################################
# Live Repository Variables
############################################

variable "aws_region" {
  description = "Approved AWS region for this live environment. Passed from AWS_DEFAULT_REGION by GitLab CI."
  type        = string
}

variable "name" {
  description = "Enterprise workload name used for the EC2 instance and required Name tag."
  type        = string
  default     = "dev-midh-ec2"
}

variable "environment" {
  description = "Enterprise environment tag value."
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Enterprise owner tag value."
  type        = string
  default     = "platform-team"
}

variable "application" {
  description = "Enterprise application tag value."
  type        = string
  default     = "maas-ec2"
}

variable "cost_center" {
  description = "Enterprise cost allocation tag value."
  type        = string
  default     = "shared-services"
}

variable "data_classification" {
  description = "Enterprise data classification tag value."
  type        = string
  default     = "internal"
}

variable "ami_id" {
  description = "Approved AMI ID for the EC2 instance."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the dev workload."
  type        = string
  default     = "t3.micro"
}

variable "vpc_id" {
  description = "Existing network foundation VPC ID."
  type        = string
}

variable "private_subnet_id" {
  description = "Existing private subnet ID for the EC2 instance."
  type        = string
}

variable "private_route_table_id" {
  description = "Route table ID associated with the private subnet for the S3 Gateway endpoint."
  type        = string
}

variable "permissions_boundary_arn" {
  description = "Enterprise IAM permissions boundary ARN for the EC2 instance role."
  type        = string
}

variable "kms_key_id" {
  description = "Optional KMS key ID or ARN for encrypted EBS volumes."
  type        = string
  default     = null
}

variable "ssm_transfer_bucket_name" {
  description = "Dedicated S3 bucket used by AWX SSM connection plugin for Ansible module transfer."
  type        = string
  default     = "midh-dev-s3"
}

variable "access_log_bucket_name" {
  description = "Existing central S3 access-log bucket that receives server access logs for the SSM transfer bucket."
  type        = string
}

variable "awx_ssm_automation_role_name" {
  description = "Existing IAM role name assumed by AWX for SSM automation and allowed by the SSM transfer bucket policy."
  type        = string
  default     = "awx-ssm-automation-role"
}
