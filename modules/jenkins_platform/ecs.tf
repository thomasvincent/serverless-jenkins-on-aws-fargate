# Jenkins Controller ECS Cluster
resource "aws_ecs_cluster" "jenkins_controller" {
  name = "${var.name_prefix}-main"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = var.tags
}

# Jenkins Agents ECS Cluster
resource "aws_ecs_cluster" "jenkins_agents" {
  name = "${var.name_prefix}-spot"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = var.tags
}

# Jenkins Controller Container Definition
data "template_file" "jenkins_controller_container_def" {
  template = file("${path.module}/templates/jenkins-controller.json.tpl")
  vars = {
    name                    = "${var.name_prefix}-controller"
    jenkins_controller_port = var.jenkins_controller_port
    jnlp_port               = var.jenkins_jnlp_port
    source_volume           = "${var.name_prefix}-efs"
    jenkins_home            = "/var/jenkins_home"
    container_image         = aws_ecr_repository.jenkins_controller.repository_url
    region                  = data.aws_region.current.name
    account_id              = data.aws_caller_identity.current.account_id
    log_group               = aws_cloudwatch_log_group.jenkins_controller.name
    memory                  = var.jenkins_controller_memory
    cpu                     = var.jenkins_controller_cpu
  }
}

# CloudWatch Log Group KMS Key
resource "aws_kms_key" "cloudwatch" {
  description = "KMS key for CloudWatch Log Group encryption"
  policy      = data.aws_iam_policy_document.cloudwatch_kms.json
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "jenkins_controller" {
  name              = var.name_prefix
  retention_in_days = var.jenkins_controller_task_log_retention_days
  kms_key_id        = aws_kms_key.cloudwatch.arn
  tags              = var.tags
}

# Jenkins Controller Task Definition
resource "aws_ecs_task_definition" "jenkins_controller" {
  family                   = var.name_prefix
  task_role_arn            = coalesce(var.jenkins_controller_task_role_arn, aws_iam_role.jenkins_controller_task[0].arn)
  execution_role_arn       = coalesce(var.ecs_execution_role_arn, aws_iam_role.jenkins_controller_execution[0].arn)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.jenkins_controller_cpu
  memory                   = var.jenkins_controller_memory
  container_definitions    = data.template_file.jenkins_controller_container_def.rendered

  volume {
    name = "${var.name_prefix}-efs"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.this.id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.this.id
        iam             = "ENABLED"
      }
    }
  }

  tags = var.tags
}

# Jenkins Controller ECS Service
resource "aws_ecs_service" "jenkins_controller" {
  name             = "${var.name_prefix}-controller"
  cluster          = aws_ecs_cluster.jenkins_controller.id
  task_definition  = aws_ecs_task_definition.jenkins_controller.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  network_configuration {
    subnets          = var.jenkins_controller_subnet_ids
    security_groups  = [aws_security_group.jenkins_controller.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.controller.arn
    port         = var.jenkins_jnlp_port
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.controller.arn
    container_name   = "${var.name_prefix}-controller"
    container_port   = var.jenkins_controller_port
  }

  depends_on = [aws_lb_listener.https]
}

# Service Discovery Namespace
resource "aws_service_discovery_private_dns_namespace" "this" {
  name        = var.name_prefix
  vpc         = var.vpc_id
  description = "Service Discovery namespace for Serverless Jenkins"
}

# Controller Service Discovery Service
resource "aws_service_discovery_service" "controller" {
  name = "controller"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.this.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    dns_records {
      ttl  = 10
      type = "SRV"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 5
  }
}
