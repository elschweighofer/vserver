# Tell terraform to use the provider and select a version.
terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
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
resource "hcloud_server" "vserver" {
  name              = "ubuntu-8gb-nbg1-1"
  server_type       = "cax21"
  image             = "ubuntu-24.04"
  datacenter        = "nbg1-dc3"
  backups           = false
  delete_protection = false
  location          = "nbg1"
  firewall_ids      = [hcloud_firewall.firewall.id,]
}
