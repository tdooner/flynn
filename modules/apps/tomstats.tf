resource "cloudflare_record" "tomstats" {
  domain = "tdooner.com"
  name = "tomstats"
  value = "f.tdooner.com"
  type = "CNAME"
  ttl = 1
  proxied = true
}
