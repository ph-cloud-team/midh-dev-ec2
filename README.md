# midh-dev-ec2

Enterprise Terraform live repository for creating one private EC2 instance in the `midh` dev AWS environment.

This repo is intentionally module-only. It does not create raw EC2, IAM, security group, VPC, subnet, S3, KMS, or VPC endpoint resources directly. Raw resources live inside certified Terraform modules or foundation/network repos.

## Architecture

```text
GitLab pipeline
  -> terraform/live/aws.yml shared pipeline
  -> GitLab HTTP Terraform state backend
  -> tf-aws-ec2-instance module from HTTP Git source pinned to v1.0.0
  -> tf-aws-s3-bucket module from HTTP Git source pinned to v1.0.0
  -> tf-aws-vpc-endpoints module from HTTP Git source pinned to v1.0.0
  -> private EC2 instance in existing VPC/subnet
  -> dedicated AWX SSM transfer bucket
  -> S3 Gateway endpoint on the private subnet route table
  -> SSM Interface endpoints in the private subnet
  -> Terraform outputs.json artifact
  -> optional AWX inventory sync
  -> awx.midhtech.local host inventory
```

## What This Repo Creates

The live repo calls the certified EC2 module using the temporary HTTP Git source pattern because this GitLab environment is not HTTPS-enabled:

```hcl
module "ec2_instance" {
  source = "git::http://gitlab.midhtech.local/cloud_team/tf-modules/aws/compute/tf-aws-ec2-instance.git?ref=v1.0.0"
}
```

The module creates:

- private EC2 instance
- IAM role and instance profile
- SSM managed instance permissions
- private-only security group
- encrypted root EBS volume
- IMDSv2 enforcement
- EC2 status check CloudWatch alarm
- optional CloudWatch agent permissions

The repo also calls the certified S3 bucket module:

```hcl
module "ssm_transfer_bucket" {
  source = "git::http://gitlab.midhtech.local/cloud_team/tf-modules/aws/storage/tf-aws-s3-bucket.git?ref=v1.0.0"
}
```

The module creates the dedicated AWX SSM transfer bucket:

- bucket name: `midh-dev-s3`
- dedicated KMS key and alias
- versioning
- server-side encryption with AWS KMS
- public access block
- server access logging
- bucket policy allowing the AWX SSM automation role to use the bucket

The repo also calls the certified VPC endpoints module:

```hcl
module "vpc_endpoints" {
  source = "git::http://gitlab.midhtech.local/cloud_team/tf-modules/aws/network/tf-aws-vpc-endpoints.git?ref=v1.0.0"
}
```

The module creates:

- S3 Gateway VPC endpoint
- association with the private subnet route table resolved from `TF_VAR_private_subnet_id`
- Interface VPC endpoints for `ssm`, `ssmmessages`, and `ec2messages`
- Interface endpoint security group allowing HTTPS from the selected VPC CIDR

## Foundation Dependencies

The selected VPC and private subnet must already exist. They should be owned by the network foundation stack.

This repo creates the required private AWS service endpoints through the
approved `tf-aws-vpc-endpoints` module because raw VPC endpoint resources are
denied in live repos. If matching endpoints were previously created manually in
AWS, delete them or import them before applying this repo; otherwise AWS may
reject duplicate endpoints for the same service and VPC.

## AWX SSM Transfer Bucket Access

The AWX automation role used by the `test-awx-aws-connect` job must use the
dedicated transfer bucket, not the Terraform state bucket:

```text
Role: awx-ssm-automation-role
Bucket: midh-dev-s3
KMS key: output ssm_transfer_bucket_kms_key_arn
```

The bucket policy is created by this live repo through the S3 module input
`bucket_policy_json`. The role still needs identity-based KMS permissions from
the IAM role owner:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3TransferBucketList",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": "arn:aws:s3:::midh-dev-s3"
    },
    {
      "Sid": "S3TransferBucketObjects",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::midh-dev-s3/*"
    },
    {
      "Sid": "S3TransferBucketKmsAccess",
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey",
        "kms:DescribeKey"
      ],
      "Resource": "<ssm_transfer_bucket_kms_key_arn>"
    }
  ]
}
```

## Pipeline Behavior

The `.gitlab-ci.yml` includes only the shared live pipeline:

```yaml
include:
  - project: infra_team/platform-pipelines
    file: terraform/live/aws.yml
```

The shared pipeline runs:

- secret detection
- pipeline policy checks
- live source OPA checks
- Checkov
- TFLint
- Terraform fmt
- Terraform validate
- Terraform plan
- Terraform plan OPA checks
- manual apply on `main`
- optional AWX inventory sync after apply

## Required GitLab CI/CD Variables

Set these variables in the `tf-live/midh-dev-ec2` GitLab project before running the pipeline.

| Variable | Required | Purpose |
| --- | --- | --- |
| `AWS_ACCESS_KEY_ID` | yes | AWS access key used by Terraform. |
| `AWS_SECRET_ACCESS_KEY` | yes | AWS secret key used by Terraform. Mark masked/protected. |
| `AWS_DEFAULT_REGION` | yes | Approved AWS region. Also feeds `TF_VAR_aws_region`. |
| `TF_HTTP_USERNAME` | yes | GitLab HTTP backend username, usually `gitlab-ci-token` or a backend service user. |
| `TF_HTTP_PASSWORD` | yes | GitLab HTTP backend token/password. Mark masked/protected. |
| `TF_VAR_ami_id` | yes | Approved AMI ID for the EC2 instance. |
| `TF_VAR_vpc_id` | yes | Existing foundation VPC ID. |
| `TF_VAR_private_subnet_id` | yes | Existing private subnet ID. |
| `TF_VAR_permissions_boundary_arn` | yes | IAM permissions boundary ARN required for the EC2 role. |
| `TF_VAR_access_log_bucket_name` | yes | Existing central S3 access-log bucket for the SSM transfer bucket. |
| `AWX_USERNAME` | required for `awx-sync` | AWX username. Mark masked/protected if sensitive. |
| `AWX_PASSWORD` | required for `awx-sync` | AWX password. Mark masked/protected. |

## Optional GitLab CI/CD Variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `TF_VAR_name` | `dev-midh-ec2` | EC2 workload name and Name tag. |
| `TF_VAR_instance_type` | `t3.micro` | EC2 instance type. |
| `TF_VAR_kms_key_id` | `null` | Optional KMS key ID or ARN for EBS encryption. |
| `TF_VAR_ssm_transfer_bucket_name` | `midh-dev-s3` | Dedicated S3 bucket used by AWX SSM module transfer. |
| `TF_VAR_awx_ssm_automation_role_name` | `awx-ssm-automation-role` | Existing AWX assume role allowed by the transfer bucket policy. |
| `TF_VAR_owner` | `platform-team` | Owner tag value. |
| `TF_VAR_application` | `midh-dev-ec2` | Application tag value. |
| `TF_VAR_cost_center` | `shared-services` | CostCenter tag value. |
| `TF_VAR_data_classification` | `internal` | DataClassification tag value. |
| `AWX_HOST` | `http://awx.midhtech.local` | AWX endpoint used by this repo. |
| `AWX_INVENTORY` | `midh-dev` | AWX inventory name. |
| `AWX_GROUP` | `midh-dev-ec2` | AWX group name for this host. |
| `AWX_ORGANIZATION` | `Default` | AWX organization used by the shared AWX sync job. |

## Apply and AWX Flow

1. Push the branch and let validation jobs run.
2. Merge to `main` after governance and plan checks pass.
3. Run the manual `apply` job from `main`.
4. Confirm Terraform creates `outputs.json` as an apply artifact.
5. Run the manual `awx-sync` job.
6. Confirm the host is created or updated in AWX inventory `midh-dev`.

The AWX host is created from Terraform outputs:

- `instance_id`
- `private_ip`
- `hostname`
- `environment`
- `application`
- `owner`

## Important Notes

The EC2 module tag must exist before this live repo can plan:

```text
cloud_team/tf-modules/aws/compute/tf-aws-ec2-instance.git tag v1.0.0
```

The EC2 module project must allow this live repo or its group to clone the module using GitLab CI job token permissions.

Destroy is controlled by the shared pipeline and requires:

- manual execution on `main`
- `ALLOW_DESTROY=true`
- `CHANGE_TICKET_ID`
