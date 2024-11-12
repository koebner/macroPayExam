# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "lb_endpoint" {
  value = "http://${aws_lb.macroPay.dns_name}"
}

output "application_endpoint" {
  value = "http://${aws_lb.macroPay.dns_name}/index.php"
}

output "asg_name" {
  value = aws_autoscaling_group.macroPay.name
}
