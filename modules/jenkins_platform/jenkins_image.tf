data "aws_ecr_authorization_token" "token" {}

locals {
  ecr_endpoint = split("/", aws_ecr_repository.jenkins_controller.repository_url)[0]
}

resource "aws_ecr_repository" "jenkins_controller" {
  name                 = var.jenkins_ecr_repository_name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

data "template_file" "jenkins_configuration" {
  template = file("${path.module}/docker/files/jenkins.yaml.tpl")
  vars = {
    ecs_cluster_fargate      = aws_ecs_cluster.jenkins_controller.arn
    ecs_cluster_fargate_spot = aws_ecs_cluster.jenkins_agents.arn
    cluster_region           = data.aws_region.current.name
    jenkins_cloud_map_name   = "controller.${var.name_prefix}"
    jenkins_controller_port  = var.jenkins_controller_port
    jnlp_port                = var.jenkins_jnlp_port
    agent_security_groups    = aws_security_group.jenkins_controller.id
    execution_role_arn       = aws_iam_role.ecs_execution.arn
    subnets                  = join(",", var.jenkins_controller_subnet_ids)
  }
}

resource "local_file" "jenkins_configuration" {
  content  = data.template_file.jenkins_configuration.rendered
  filename = "${path.module}/docker/files/jenkins.yaml"
}

resource "null_resource" "build_docker_image" {
  triggers = {
    config_file_hash = filemd5("${path.module}/docker/files/jenkins.yaml")
    docker_file_hash = filemd5("${path.module}/docker/Dockerfile")
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo ${data.aws_ecr_authorization_token.token.password} | docker login -u AWS --password-stdin ${local.ecr_endpoint}
      docker build -t ${aws_ecr_repository.jenkins_controller.repository_url}:latest ${path.module}/docker/
      docker push ${aws_ecr_repository.jenkins_controller.repository_url}:latest
    EOT
  }

  depends_on = [local_file.jenkins_configuration]
}
