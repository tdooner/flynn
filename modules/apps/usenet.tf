resource "cloudflare_record" "sabnzbd" {
  domain = "tdooner.com"
  name = "sabnzbd"
  value = "f.tdooner.com"
  type = "CNAME"
  proxied = true
}

resource "cloudflare_record" "sickbeard" {
  domain = "tdooner.com"
  name = "sickbeard"
  value = "f.tdooner.com"
  type = "CNAME"
  proxied = true
}
