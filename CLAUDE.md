# Serverless Jenkins on AWS Fargate

## Purpose
Terraform module deploying serverless Jenkins on AWS Fargate with ECS, EFS, ALB, and Cloud Map.

## Stack
- Terraform 0.14+ (HCL)
- AWS provider (ECS, EFS, ALB, ECR, IAM, Route53, CloudMap, Backup)
- Docker (Jenkins controller image)

## Structure
- `modules/jenkins_platform/` - main module
- `example/` - deployable example with bootstrap

## Build & Test
```bash
terraform init
terraform validate
terraform plan
terraform apply
```

## Standards
- Tag all AWS resources consistently
- Variables with descriptions and types in `variables.tf`
- Outputs in `outputs.tf`
- Sensitive values via SSM Parameter Store (e.g., `jenkins-pwd`)
- Conventional Commits: `type(scope): description`

## Conventions
- Private subnets for ECS tasks and EFS
- ACM certificate required for ALB HTTPS
- S3 backend with DynamoDB locking for state
