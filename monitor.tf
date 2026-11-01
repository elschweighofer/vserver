# Uptime monitor: a Cloudflare Worker that checks the site every 5 minutes and
# sends an ntfy push on failure. Use a hostname in monitor_urls, not a bare IP.
variable "cloudflare_api_token" {
  description = "Token with Workers Scripts Edit on the account"
  sensitive   = true
}

variable "cloudflare_account_id" {
  type = string
}

variable "monitor_urls" {
  description = "URLs to check, for example [\"http://example.com/\"]"
  type        = list(string)
}

# Anyone with this URL can read or send alerts, so keep the topic unguessable.
variable "ntfy_url" {
  description = "ntfy topic URL, for example https://ntfy.sh/<long random name>"
  sensitive   = true
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "cloudflare_workers_script" "monitor" {
  account_id         = var.cloudflare_account_id
  script_name        = "vserver-monitor"
  content            = file("${path.module}/monitor/worker.js")
  main_module        = "worker.js"
  compatibility_date = "2026-10-01"

  bindings = [
    {
      type = "plain_text"
      name = "MONITOR_URLS"
      text = jsonencode(var.monitor_urls)
    },
    {
      type = "secret_text"
      name = "NTFY_URL"
      text = var.ntfy_url
    },
  ]
}

resource "cloudflare_workers_cron_trigger" "monitor" {
  account_id  = var.cloudflare_account_id
  script_name = cloudflare_workers_script.monitor.script_name
  schedules   = [{ cron = "*/5 * * * *" }]
}
