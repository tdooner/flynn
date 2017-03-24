resource "cloudflare_record" "disclosure-backend-static" {
  domain = "tdooner.com"
  name = "disclosure-backend-static"
  value = "f.tdooner.com"
  type = "CNAME"
  proxied = true
}

module "disclosure_backend_status_check" {
  source = "../aws-status-check"

  fqdn = "disclosure-backend-static.tdooner.com"
  type = "HTTPS"
  port = 443
  sns_arn = "arn:aws:sns:us-east-1:428663493796:downtime-alerts"
}
