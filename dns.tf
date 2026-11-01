# The zone itself is managed in the Cloudflare dashboard. The token needs
# Zone > DNS > Edit on it. DNS only, so visitors connect straight to the server.
resource "cloudflare_dns_record" "site" {
  zone_id = "6fdf99068627224ffbdd60e3317a0371"
  name    = "epubs.fyi"
  type    = "A"
  content = hcloud_primary_ip.vserver.ip_address
  ttl     = 300
  proxied = false
}
