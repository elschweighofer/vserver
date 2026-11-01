# Tell terraform to use the provider and select a version.
terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.70"
    }
  }
}


# Set the variable value in *.tfvars file
# or using the -var="hcloud_token=..." CLI option
variable "hcloud_token" {
  sensitive = true
}
# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hcloud_token
}
resource "hcloud_firewall" "firewall" {
  name = "firewall-1"
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
  rule {
    description     = "PING"
    destination_ips = []
    direction       = "in"
    protocol        = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0",
    ]
  }
  rule {
    description     = "SSH"
    destination_ips = []
    direction       = "in"
    port            = "22"
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

  public_net {
    ipv4_enabled = true
    ipv4         = hcloud_primary_ip.vserver.id
    ipv6_enabled = true
  }
}

output "ipv4_address" {
  value = hcloud_primary_ip.vserver.ip_address
}
