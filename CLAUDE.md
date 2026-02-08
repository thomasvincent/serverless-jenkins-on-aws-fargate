# CLAUDE.md

Terraform module deploying serverless Jenkins on AWS Fargate with dual cluster setup (FARGATE + FARGATE_SPOT).

## Stack
- Terraform 0.14+
- AWS ECS Fargate
- Amazon EFS for stateful storage

## Prerequisites Check

```bash
# Verify SSM parameter exists
aws ssm get-parameter --name jenkins-pwd --with-decryption

# Validate configuration
terraform fmt -check
terraform validate
terraform plan
```

## Architecture Highlights
- Dual ECS clusters: standard FARGATE for controller/high-priority, FARGATE_SPOT for low-priority agents
- EFS with AWS Backup vault for Jenkins home persistence
- ALB with ACM certificate for HTTPS access
- Cloud Map service discovery for agent-to-controller communication
- ECR repository for custom Jenkins controller image with amazon-ecs-plugin
