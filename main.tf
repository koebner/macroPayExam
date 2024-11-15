provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      macroPay-exam = "aws-asg"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name = "macroPay-vpc"
  cidr = "10.0.0.0/16"

  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.4.0/24","10.0.5.0/24"]
  private_subnets = [ "10.0.14.0/24","10.0.15.0/24" ]
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# resource "aws_key_pair" "ssh_key" {
#   key_name   = "mcPayKey"
#   public_key = file("mcPayKey.pub") # Asegúrate de tener tu clave pública aquí
# }

resource "aws_launch_configuration" "terraform_macroPay" {
  name_prefix     = "macroPay-terraform-aws-asg-"
  image_id        = "ami-0984f4b9e98be44bf"
  # key_name = aws_key_pair.ssh_key.key_name
  key_name = "macroPayKey"
  instance_type   = "t2.micro"
  user_data       = file("user-data.sh")
  security_groups = [aws_security_group.macroPay_instance.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "macroPay" {
  name                 = "macroPay-auto-scaling-group"
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.terraform_macroPay.name
  vpc_zone_identifier  = module.vpc.public_subnets

  health_check_type    = "ELB"

  tag {
    key                 = "Name"
    value               = "autoScalingGroup - macroPay"
    propagate_at_launch = true
  }
}
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.macroPay.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.macroPay.name
}


resource "aws_lb" "macroPay" {
  name               = "macroPay-asg-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.macroPay_lb.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_listener" "macroPay" {
  load_balancer_arn = aws_lb.macroPay.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.macroPay.arn
  }
}

resource "aws_lb_target_group" "macroPay" {
  name     = "macroPay-terraform-aws-asg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}


resource "aws_autoscaling_attachment" "macroPay" {
  autoscaling_group_name = aws_autoscaling_group.macroPay.id
  alb_target_group_arn   = aws_lb_target_group.macroPay.arn
}

resource "aws_security_group" "macroPay_instance" {
  name = "macroPay-terraform-aws-asg-instance"
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.macroPay_lb.id]

  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group" "macroPay_lb" {
  name = "macroPay-terraform-aws-asg-lb"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = module.vpc.vpc_id
}

