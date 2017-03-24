variable "fqdn" {}
variable "type" {}
variable "port" {}
variable "sns_arn" {}

provider "aws" {
  region = "us-east-1"
  alias = "east"
}

resource "aws_cloudwatch_metric_alarm" "check" {
  metric_name = "HealthCheckStatus"
  comparison_operator = "LessThanThreshold"
  threshold = "1"
  evaluation_periods = "1"
  period = "60" # seconds
  statistic = "Minimum"

  alarm_name = "${var.fqdn}"
  namespace = "AWS/Route53"
  provider = "aws.east"

  dimensions {
    HealthCheckId = "${aws_route53_health_check.check.id}"
  }

  alarm_actions = ["${var.sns_arn}"]
}

resource "aws_route53_health_check" "check" {
  fqdn = "${var.fqdn}"
  port = "${var.port}"
  type = "${var.type}"
  failure_threshold = "1" # TODO: bump this up to 5
  request_interval = "30"

  tags = {
    Name = "${var.fqdn}"
  }
}
