variable "jenkins_ecr_repository_name" {
  type        = string
  default     = "serverless-jenkins-controller"
  description = "Name for Jenkins controller ECR repository"
}

variable "name_prefix" {
  type        = string
  default     = "serverless-jenkins"
  description = "Prefix to be used in the name of resources"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC where resources will be created"
}

variable "efs_enable_encryption" {
  type        = bool
  default     = true
  description = "Whether to enable encryption for EFS"
}

variable "efs_kms_key_arn" {
  type        = string
  default     = null
  description = "ARN of the KMS key to use for EFS encryption (defaults to aws/elasticfilesystem)"
}

variable "efs_performance_mode" {
  type        = string
  default     = "generalPurpose"
  description = "Performance mode of the EFS file system (generalPurpose or maxIO)"
}

variable "efs_throughput_mode" {
  type        = string
  default     = "bursting"
  description = "Throughput mode of the EFS file system (bursting or provisioned)"
}

variable "efs_provisioned_throughput_in_mibps" {
  type        = number
  default     = null
  description = "Provisioned throughput in MiB/s for EFS when throughput mode is set to provisioned"
}

variable "efs_ia_lifecycle_policy" {
  type        = string
  default     = null
  description = "EFS Infrequent Access (IA) lifecycle policy (AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS)"
}

variable "efs_subnet_ids" {
  type        = list(string)
  default     = null
  description = "List of subnet IDs to attach to the EFS mount target"
}

variable "efs_access_point_uid" {
  type        = number
  default     = 1000
  description = "User ID (uid) to associate with the EFS access point (default: 1000)"
}

variable "efs_access_point_gid" {
  type        = number
  default     = 1000
  description = "Group ID (gid) to associate with the EFS access point (default: 1000)"
}

variable "efs_enable_backup" {
  type        = bool
  default     = true
  description = "Whether to enable automated backups for EFS"
}

variable "efs_backup_schedule" {
  type        = string
  default     = "cron(0 00 * * ? *)"
  description = "Cron schedule expression for EFS backup"
}

variable "efs_backup_start_window" {
  type        = number
  default     = 60
  description = "Number of minutes to allow a backup job to start before canceling"
}

variable "efs_backup_completion_window" {
  type        = number
  default     = 120
  description = "Number of minutes to allow a backup job to complete before canceling"
}

variable "efs_backup_cold_storage_after_days" {
  type        = number
  default     = 30
  description = "Number of days until the EFS backup is moved to cold storage"
}

variable "efs_backup_delete_after_days" {
  type        = number
  default     = 120
  description = "Number of days until the EFS backup is deleted (must be 90 days greater than cold storage transition)"
}

variable "alb_type_internal" {
  type        = bool
  default     = false
  description = "Whether the Application Load Balancer should be internal"
}

variable "alb_enable_access_logs" {
  type        = bool
  default     = false
  description = "Whether to enable access logging for the Application Load Balancer"
}

variable "alb_access_logs_bucket_name" {
  type        = string
  default     = null
  description = "Name of the S3 bucket to store ALB access logs"
}

variable "alb_access_logs_s3_prefix" {
  type        = bool
  default     = null
  description = "Prefix to use for ALB access logs stored in S3"
}

variable "alb_create_security_group" {
  type        = bool
  default     = true
  description = "Whether to create a security group for the ALB (if false, 'alb_security_group_ids' must be provided)"
}

variable "alb_security_group_ids" {
  type        = list(string)
  default     = null
  description = "List of security group IDs to associate with the ALB (required if 'alb_create_security_group' is false)"
}

variable "alb_ingress_allow_cidrs" {
  type        = list(string)
  default     = null
  description = "List of CIDRs to allow inbound traffic to Jenkins through the ALB"
}

variable "alb_subnet_ids" {
  type        = list(string)
  default     = null
  description = "List of subnet IDs to associate with the ALB"
}

variable "alb_acm_certificate_arn" {
  type        = string
  description = "ARN of the ACM certificate to use for HTTPS on the ALB"
}

variable "jenkins_controller_port" {
  type        = number
  default     = 8080
  description = "Port number for the Jenkins controller"
}

variable "jenkins_jnlp_port" {
  type        = number
  default     = 50000
  description = "Port number for the Jenkins JNLP agent"
}

variable "jenkins_controller_cpu" {
  type        = number
  default     = 2048
  description = "CPU units for the Jenkins controller Fargate task"
}

variable "jenkins_controller_memory" {
  type        = number
  default     = 4096
  description = "Memory (in MiB) for the Jenkins controller Fargate task"
}

variable "jenkins_controller_task_log_retention_days" {
  type        = number
  default     = 30
  description = "Number of days to retain Jenkins controller task logs in CloudWatch"
}

variable "jenkins_controller_subnet_ids" {
  type        = list(string)
  default     = null
  description = "List of subnet IDs for the Jenkins controller Fargate service"
}

variable "jenkins_controller_task_role_arn" {
  type        = string
  default     = null
  description = "ARN of the custom IAM task role for the Jenkins controller Fargate task"
}

variable "ecs_execution_role_arn" {
  type        = string
  default     = null
  description = "ARN of the custom IAM execution role for ECS tasks"
}

variable "route53_create_alias" {
  type        = string
  default     = false
  description = "Whether to create a Route 53 alias record for the ALB"
}

variable "route53_zone_id" {
  type        = string
  default     = null
  description = "ID of the Route 53 hosted zone to create the alias record in"
}

variable "route53_alias_name" {
  type        = string
  default     = "jenkins-controller"
  description = "Name of the Route 53 alias record"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Map of tags to assign to resources"
}
