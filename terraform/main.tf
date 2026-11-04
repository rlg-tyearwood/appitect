resource "random_password" "root_pass" {
  length           = 32
  special          = true
  override_special = "!@#%^&*()-_=+"
}

resource "random_password" "panel_password" {
  length  = 24
  special = false
}

resource "random_string" "panel_entrance" {
  length  = 12
  upper   = false
  special = false
}

locals {
  name_prefix            = "appitect-${var.app_slug}-${var.environment}"
  effective_panel_pass   = var.panel_password != "" ? var.panel_password : random_password.panel_password.result
  effective_panel_slug   = var.panel_entrance != "" ? var.panel_entrance : random_string.panel_entrance.result
  internal_network_name  = "${replace(var.app_slug, "-", "_")}_internal"

  rendered_caddyfile = templatefile("${path.module}/../edge/Caddyfile.tftpl", {
    acme_email             = var.acme_email
    app_slug               = var.app_slug
    app_domain             = var.app_domain
    app_upstream_container = var.app_upstream_container
    app_upstream_port      = var.app_upstream_port
    waf_mode               = var.waf_mode
    max_body_size          = "${var.max_body_mb}MB"
    max_body_bytes         = var.max_body_mb * 1048576
    enable_panel_subdomain = var.enable_panel_subdomain
    panel_domain           = var.panel_domain
    panel_port             = var.panel_port
  })

  cloud_init_config = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    hostname              = local.name_prefix
    app_slug              = var.app_slug
    internal_network_name = local.internal_network_name
    ssh_public_key        = trimspace(var.ssh_public_key)
    panel_port            = var.panel_port
    panel_username        = var.panel_username
    panel_password        = local.effective_panel_pass
    panel_entrance        = local.effective_panel_slug
    dockerfile_caddy_b64  = base64encode(file("${path.module}/../edge/Dockerfile.caddy"))
    compose_edge_b64      = base64encode(file("${path.module}/../edge/docker-compose.yml"))
    caddyfile_b64         = base64encode(local.rendered_caddyfile)
  })
}

resource "linode_sshkey" "deploy" {
  label   = "${local.name_prefix}-key"
  ssh_key = chomp(trimspace(var.ssh_public_key))
}

resource "linode_instance" "vps" {
  label           = local.name_prefix
  image           = var.vps_image
  region          = var.linode_region
  type            = var.vps_type
  backups_enabled = var.backups_enabled
  private_ip      = true
  root_pass       = random_password.root_pass.result
  authorized_keys = [linode_sshkey.deploy.ssh_key]
  tags            = ["appitect", "dedicated", var.app_slug, var.environment]

  metadata {
    user_data = base64encode(local.cloud_init_config)
  }

  lifecycle {
    # Prevent Day-2 Caddy/WAF variable tweaks from destroying and recreating a live production VPS.
    # Use ./scripts/sync-edge.sh to push live Caddy/Coraza updates without downtime.
    ignore_changes = [metadata, root_pass]
  }
}

locals {
  public_ipv4 = [
    for ip in linode_instance.vps.ipv4 : ip
    if !startswith(ip, "192.168.") && !startswith(ip, "10.")
  ][0]
  public_ipv6 = split("/", linode_instance.vps.ipv6)[0]
}

resource "linode_firewall" "edge" {
  label           = substr("${local.name_prefix}-fw", 0, 32)
  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"

  inbound {
    label    = "allow-ssh-tcp"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = var.ssh_allowed_ipv4
    ipv6     = var.ssh_allowed_ipv6
  }

  inbound {
    label    = "allow-http-tcp"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "80"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "allow-https-tcp"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "443"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  inbound {
    label    = "allow-http3-udp"
    action   = "ACCEPT"
    protocol = "UDP"
    ports    = "443"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  linodes = [linode_instance.vps.id]
}

resource "linode_database_postgresql_v2" "db" {
  count        = var.enable_managed_postgres ? 1 : 0
  label        = substr("${local.name_prefix}-pg", 0, 32)
  engine_id    = var.postgres_engine_id
  region       = var.linode_region
  type         = var.postgres_node_type
  cluster_size = var.postgres_cluster_size

  allow_list = distinct(concat(
    ["${local.public_ipv4}/32", "${local.public_ipv6}/128"],
    var.postgres_extra_allow_cidrs
  ))
}
