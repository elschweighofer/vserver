# Tell terraform to use the provider and select a version.
terraform {
  # Credentials come from AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY in .env.
  backend "s3" {
    bucket = "tado1maqzuxtodcec"
    key    = "vserver/terraform.tfstate"
    region = "nbg1"

    endpoints = {
      s3 = "https://nbg1.your-objectstorage.com"
    }

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true

    use_lockfile = true
  }

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.70"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}


# Set the variable value in *.tfvars file
# or using the -var="hcloud_token=..." CLI option
variable "hcloud_token" {
  sensitive = true
}

# Stored in the Terraform state as part of user_data.
variable "wg_server_private_key" {
  description = "WireGuard private key of this server"
  sensitive   = true
}

variable "wg_home_public_key" {
  description = "WireGuard public key of the home webserver"
  type        = string

  validation {
    condition     = length(var.wg_home_public_key) == 44
    error_message = "Expected a 44 character WireGuard public key."
  }
}

locals {
  wg_port           = 51820
  wg_server_address = "10.99.0.1"
  wg_home_address   = "10.99.0.2"
}

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hcloud_token
}
resource "hcloud_firewall" "firewall" {
  name = "firewall-1"
  rule {
    description     = "HTTP"
    destination_ips = []
    direction       = "in"
    port            = "80"
    protocol        = "tcp"
    source_ips = [
      "0.0.0.0/0",
      "::/0",
    ]
  }
  rule {
    description     = "WireGuard"
    destination_ips = []
    direction       = "in"
    port            = tostring(local.wg_port)
    protocol        = "udp"
    source_ips = [
      "0.0.0.0/0",
      "::/0",
    ]
  }
  rule {
    description     = "HTTPS"
    destination_ips = []
    direction       = "in"
    port            = "443"
    protocol        = "tcp"
    source_ips = [
      "0.0.0.0/0",
      "::/0",
    ]
  }
}

# Key already uploaded to the Hetzner project; only referenced here.
data "hcloud_ssh_key" "lukas" {
  name = "lukas@MacBookAir"
}

# Lives and dies with the server: `terraform destroy` removes both.
# auto_delete stays false so Terraform, not Hetzner, deletes it. With true,
# replacing the server would delete the IP the new server is about to use.
resource "hcloud_primary_ip" "vserver" {
  name        = "primary_ip-96739942"
  location    = "nbg1"
  type        = "ipv4"
  auto_delete = false
}

resource "hcloud_server" "vserver" {
  name              = "ubuntu-2c-4gb-nbg1-1"
  server_type       = "cx23"
  image             = "ubuntu-24.04"
  backups           = false
  delete_protection = false
  location          = "nbg1"
  firewall_ids      = [hcloud_firewall.firewall.id, ]
  ssh_keys          = [data.hcloud_ssh_key.lukas.id]

  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    wg_port               = local.wg_port
    wg_server_address     = local.wg_server_address
    wg_home_address       = local.wg_home_address
    wg_server_private_key = var.wg_server_private_key
    wg_home_public_key    = var.wg_home_public_key
  })

  public_net {
    ipv4_enabled = true
    ipv4         = hcloud_primary_ip.vserver.id
    ipv6_enabled = true
  }
}

output "ipv4_address" {
  value = hcloud_primary_ip.vserver.ip_address
}
