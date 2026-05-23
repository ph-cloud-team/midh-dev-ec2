############################################
# AWX SSM Transfer Bucket
############################################

# Creates the dedicated S3 transfer bucket used by the AWX SSM connection
# plugin. Live repos must consume approved modules instead of defining raw S3
# resources directly.
module "ssm_transfer_bucket" {
  source = "git::http://gitlab.midhtech.local/cloud_team/tf-modules/aws/storage/tf-aws-s3-bucket.git?ref=v1.0.0"

  bucket_name   = var.ssm_transfer_bucket_name
  kms_key_alias = var.ssm_transfer_bucket_name

  access_logging = {
    target_bucket = var.access_log_bucket_name
    target_prefix = "${var.environment}/${var.application}/ssm-transfer/"
  }

  bucket_policy_json = data.aws_iam_policy_document.ssm_transfer_bucket.json

  tags = {
    Name               = var.ssm_transfer_bucket_name
    Environment        = var.environment
    Owner              = var.owner
    Application        = var.application
    CostCenter         = var.cost_center
    DataClassification = var.data_classification
  }
}

############################################
# Private S3 Connectivity for AWX SSM
############################################

# Creates all AWS private service endpoints needed by SSM-managed EC2 through
# the approved network module. The S3 Gateway endpoint supports Ansible module
# transfer through the dedicated bucket; the Interface endpoints support SSM
# control and command channels.
module "vpc_endpoints" {
  source = "git::http://gitlab.midhtech.local/cloud_team/tf-modules/aws/network/tf-aws-vpc-endpoints.git?ref=v1.0.0"

  vpc_id = data.aws_vpc.selected.id

  create_interface_endpoint_security_group = true
  interface_endpoint_ingress_cidr_blocks   = [data.aws_vpc.selected.cidr_block]

  endpoints = {
    s3 = {
      service           = "s3"
      vpc_endpoint_type = "Gateway"
      route_table_ids   = [data.aws_route_table.private.id]
    }

    ssm = {
      service             = "ssm"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = [data.aws_subnet.private.id]
      private_dns_enabled = true
    }

    ssmmessages = {
      service             = "ssmmessages"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = [data.aws_subnet.private.id]
      private_dns_enabled = true
    }

    ec2messages = {
      service             = "ec2messages"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = [data.aws_subnet.private.id]
      private_dns_enabled = true
    }
  }

  tags = {
    Name               = var.name
    Environment        = var.environment
    Owner              = var.owner
    Application        = var.application
    CostCenter         = var.cost_center
    DataClassification = var.data_classification
  }
}

############################################
# EC2 Workload Composition
############################################

# Creates the dev EC2 instance by consuming the approved EC2 module from GitLab.
module "ec2_instance" {
  # Uses temporary HTTP Git source because this GitLab environment is HTTP-only.
  source = "git::http://gitlab.midhtech.local/cloud_team/tf-modules/aws/compute/tf-aws-ec2-instance.git?ref=v1.0.0"

  # Sets the enterprise workload name and Name tag.
  name = var.name

  # Supplies the approved AMI ID from the dev account image catalog or CI variable.
  ami_id = var.ami_id

  # Sets the EC2 instance size for this environment.
  instance_type = var.instance_type

  # Passes the foundation-owned VPC ID to the module.
  vpc_id = data.aws_vpc.selected.id

  # Passes the foundation-owned private subnet ID to the module.
  subnet_id = data.aws_subnet.private.id

  # Applies the enterprise IAM permissions boundary to the module-managed role.
  permissions_boundary_arn = var.permissions_boundary_arn

  # Uses an optional KMS key for EBS encryption when supplied.
  kms_key_id = var.kms_key_id

  # Allows only HTTPS egress to the VPC CIDR by default.
  egress_cidr_blocks = [data.aws_vpc.selected.cidr_block]

  # Allows HTTPS egress to the regional S3 Gateway endpoint prefix list for
  # AWX SSM module transfer through the dedicated S3 bucket.
  egress_prefix_list_ids = [data.aws_prefix_list.s3.id]

  # Enables CloudWatch agent permissions for AWX Day-2 configuration.
  attach_cloudwatch_agent_policy = true

  # Applies mandatory enterprise tags to all supported resources.
  tags = {
    Name               = var.name
    Environment        = var.environment
    Owner              = var.owner
    Application        = var.application
    CostCenter         = var.cost_center
    DataClassification = var.data_classification
  }

  # Makes private endpoint creation explicit before the instance module is planned.
  depends_on = [module.vpc_endpoints]
}
