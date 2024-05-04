data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_security_group" "efs" {
  name        = "${var.name_prefix}-efs"
  description = "${var.name_prefix} EFS security group"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_controller.id]
    from_port       = 2049
    to_port         = 2049
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_security_group" "jenkins_controller" {
  name        = "${var.name_prefix}-controller"
  description = "${var.name_prefix} Jenkins controller security group"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    self            = true
    security_groups = var.alb_create_security_group ? [aws_security_group.alb[0].id] : var.alb_security_group_ids
    from_port       = var.jenkins_controller_port
    to_port         = var.jenkins_controller_port
    description     = "Communication channel to Jenkins leader"
  }

  ingress {
    protocol        = "tcp"
    self            = true
    security_groups = var.alb_create_security_group ? [aws_security_group.alb[0].id] : var.alb_security_group_ids
    from_port       = var.jenkins_jnlp_port
    to_port         = var.jenkins_jnlp_port
    description     = "Communication channel to Jenkins leader"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_security_group" "alb" {
  count = var.alb_create_security_group ? 1 : 0

  name        = "${var.name_prefix}-alb"
  description = "${var.name_prefix} ALB security group"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = var.alb_ingress_allow_cidrs
    description = "HTTP public access"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = var.alb_ingress_allow_cidrs
    description = "HTTPS public access"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_lb" "this" {
  name               = replace("${var.name_prefix}-controller-alb", "_", "-")
  internal           = var.alb_type_internal
  load_balancer_type = "application"
  security_groups    = var.alb_create_security_group ? [aws_security_group.alb[0].id] : var.alb_security_group_ids
  subnets            = var.alb_subnet_ids

  dynamic "access_logs" {
    for_each = var.alb_enable_access_logs ? [true] : []
    content {
      bucket  = var.alb_access_logs_bucket_name
      prefix  = var.alb_access_logs_s3_prefix
      enabled = true
    }
  }

  tags = var.tags
}

resource "aws_lb_target_group" "this" {
  name        = replace("${var.name_prefix}-controller", "_", "-")
  port        = var.jenkins_controller_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled = true
    path    = "/login"
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-Res-2019-08"
  certificate_arn   = var.alb_acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_lb_listener_rule" "redirect_http_to_https" {
  listener_arn = aws_lb_listener.http.arn

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

resource "aws_route53_record" "this" {
  count = var.route53_create_alias ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.route53_alias_name
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}
