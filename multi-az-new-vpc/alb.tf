##################################################################
# Application Load Balancer
##################################################################

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "10.4.0"

  name               = "alb-${local.name}"
  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [module.alb_security_group.security_group_id]

  # Prevent deletion of the ALB (defaults to true)
  enable_deletion_protection = false
  create_security_group      = false

  listeners = {
    http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = var.acm_certificate_arn

      forward = {
        # The value of the `target_group_key` is the key used in the `target_groups` map below
        target_group_key = "instance-target"
      }
    }
  }

  target_groups = {
    # This key name is used by the listener/listener rules to know which target to forward traffic to
    instance-target = {
      name_prefix = "app"
      protocol    = "HTTP"
      port        = var.app_port
      target_type = "instance"
      target_id   = aws_instance.app.id
      health_check = {
        enabled             = true
        protocol            = "HTTP"
        path                = "/health"
        matcher             = "200"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
      }
    }
  }

  tags = local.tags
}
