resource "cloudflare_record" "disclosure-backend-static" {
  domain = "tdooner.com"
  name = "disclosure-backend-static"
  value = "f.tdooner.com"
  type = "CNAME"
  proxied = true
}
