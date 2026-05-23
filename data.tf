############################################
# Existing Foundation Resource Lookups
############################################

# Reads the selected VPC owned by the network foundation stack.
data "aws_vpc" "selected" {
  # Uses a VPC ID supplied through GitLab CI/CD variables.
  id = var.vpc_id
}

# Reads the selected private subnet owned by the network foundation stack.
data "aws_subnet" "private" {
  # Uses a private subnet ID supplied through GitLab CI/CD variables.
  id = var.private_subnet_id
}

# Reads the route table associated with the selected private subnet.
# Data sources are allowed in live repos; the raw endpoint resource is created
# inside the approved VPC endpoints module.
data "aws_route_table" "private" {
  route_table_id = var.private_route_table_id
}

# Reads the AWS-managed S3 prefix list used by the S3 Gateway endpoint route.
data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${var.aws_region}.s3"
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_iam_policy_document" "ssm_transfer_bucket" {
  statement {
    sid    = "AllowAwxSsmRoleBucketAccess"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${var.awx_ssm_automation_role_name}"
      ]
    }

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.ssm_transfer_bucket_name}"
    ]
  }

  statement {
    sid    = "AllowAwxSsmRoleObjectAccess"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${var.awx_ssm_automation_role_name}"
      ]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${var.ssm_transfer_bucket_name}/*"
    ]
  }
}
