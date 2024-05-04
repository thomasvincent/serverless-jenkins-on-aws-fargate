output "efs_file_system_id" {
  value       = aws_efs_file_system.this.id
  description = "The ID of the EFS file system"
}

output "efs_file_system_dns_name" {
  value       = aws_efs_file_system.this.dns_name
  description = "The DNS name of the EFS file system"
}

output "efs_access_point_id" {
  value       = aws_efs_access_point.this.id
  description = "The ID of the EFS access point"
}

output "efs_security_group_id" {
  value       = aws_security_group.efs.id
  description = "The ID of the EFS security group"
}

output "efs_aws_backup_plan_name" {
  value       = aws_backup_plan.this[*].name
  description = "The name of the AWS Backup plan used for EFS backups"
}

output "efs_aws_backup_vault_name" {
  value       = aws_backup_vault.this[*].name
  description = "The name of the AWS Backup vault used for EFS backups"
}
