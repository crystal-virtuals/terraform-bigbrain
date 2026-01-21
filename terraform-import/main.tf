##################################################################
# ALB
##################################################################

resource "aws_lb" "app_alb" {
  internal           = false
  ip_address_type    = "ipv4"
  load_balancer_type = "application"
  name               = "test"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = [aws_subnet.subnet_public_usw2a.id, aws_subnet.subnet_public_usw2b.id, aws_subnet.subnet_public_usw2c.id, aws_subnet.subnet_public_usw2d.id]
}

resource "aws_lb_target_group" "app_tg" {
  name        = "bigbrain-api-http-5005"
  port        = 5005
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    healthy_threshold   = 5
    interval            = 30
    timeout             = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http_80" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }

  #   default_action {
  #     type = "redirect"
  #     redirect {
  #       port        = "443"
  #       protocol    = "HTTPS"
  #       status_code = "HTTP_301"
  #     }
  #   }

}

resource "aws_lb_listener" "https_443" {
  certificate_arn   = "arn:aws:acm:us-west-2:929593185725:certificate/a2886cca-15bc-4a14-a053-5b44f1b964db"
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

##################################################################
# EC2
##################################################################

resource "aws_instance" "app_server" {
  ami               = "ami-0ebf411a80b6b22cb"
  instance_type     = "t3.micro"
  key_name          = "bigbrain-key"
  availability_zone = "us-west-2c"

  subnet_id = aws_subnet.subnet_public_usw2c.id

  vpc_security_group_ids = [
    aws_security_group.sg_ec2.id,     # launch-wizard-1 (sg-02a920375c764912e)
    aws_security_group.sg_ec2_rds.id, # ec2-rds-1 (sg-0daf2a16e2fabe299)
  ]

  associate_public_ip_address = true

  tags = {
    Name = "bigbrain"
  }
}

##################################################################
# Amplify
##################################################################

resource "aws_amplify_app" "frontend" {
  name       = "bigbrain"
  repository = "https://github.com/crystal-virtuals/bigbrain"
  platform   = "WEB"

  environment_variables = {
    AMPLIFY_DIFF_DEPLOY       = "false"
    AMPLIFY_MONOREPO_APP_ROOT = "frontend"
  }

  build_spec = <<-YAML
  version: 1
  applications:
    - frontend:
        phases:
          preBuild:
            commands:
              - npm ci --cache .npm --prefer-offline
          build:
            commands:
              - npm run build
        artifacts:
          baseDirectory: dist
          files:
            - '**/*'
        cache:
          paths:
            - .npm/**/*
      appRoot: frontend
  YAML

  custom_rule {
    source = "/<*>"
    status = "404-200"
    target = "/index.html"
  }
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.frontend.id
  branch_name = "main"

  enable_auto_build   = true
  enable_basic_auth   = false
  enable_notification = false

  framework = "Web"
  stage     = "PRODUCTION"
}
