################################################################################
# IAM - Session Manager
################################################################################

resource "aws_iam_role" "ec2_role" {
  name = "ec2-role-${local.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.project_name}-instance_profile"
  role = aws_iam_role.ec2_role.name
}

##################################################################
# EC2
##################################################################

# Data source to fetch the latest Amazon Linux 2023 (AL2023 x86_64) AMI ID
data "aws_ami" "amzn-linux-2023-ami" {
  most_recent = true
  owners      = ["amazon"] # or ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create an EC2 instance
resource "aws_instance" "app" {
  ami           = data.aws_ami.amzn-linux-2023-ami.id # Fetching the latest AL2023 AMI ID from the data source
  instance_type = var.ec2_instance_type

  subnet_id              = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids = [module.app_security_group.security_group_id]

  # IAM role for EC2 instance
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  associate_public_ip_address = true

  # Provisioning script to install node, clone repo and run the backend as a service.
  user_data                   = base64encode(local.user_data)
  user_data_replace_on_change = true

  tags = merge({ Name = "${local.name}-app-server" }, local.tags)
}
