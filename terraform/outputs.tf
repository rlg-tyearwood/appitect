output "rendered_caddyfile" {
  description = "Rendered Caddyfile with Coraza OWASP WAF rules for Day-2 live updates via scripts/sync-edge.sh."
  value       = local.rendered_caddyfile
}

output "vps_id" {
  description = "Linode instance ID of the dedicated VPS."
  value       = linode_instance.vps.id
}

output "vps_public_ipv4" {
  description = "Primary public IPv4 address of the dedicated VPS (point your domain's DNS A record here)."
  value       = local.public_ipv4
}

output "vps_public_ipv6" {
  description = "Public IPv6 address of the dedicated VPS (point your domain's DNS AAAA record here)."
  value       = local.public_ipv6
}

output "ssh_deploy_command" {
  description = "SSH command to connect as the hardened 'deploy' user."
  value       = "ssh deploy@${local.public_ipv4}"
}

output "app_deploy_directory" {
  description = "Directory on the VPS reserved for the dedicated application's docker-compose deployment."
  value       = "/opt/apps/${var.app_slug}"
}

output "docker_networks" {
  description = "Pre-provisioned Docker bridge networks on the dedicated VPS."
  value = {
    edge_network     = "vps_edge"
    internal_network = local.internal_network_name
  }
}

output "onepanel_ssh_tunnel_command" {
  description = "SSH local port-forwarding command to securely access the 1Panel Web UI without exposing its port publicly."
  value       = "ssh -L ${var.panel_port}:127.0.0.1:${var.panel_port} deploy@${local.public_ipv4}"
}

output "onepanel_credentials" {
  description = "1Panel login URL, username, password, and security entrance slug."
  sensitive   = true
  value = {
    local_tunnel_url = "http://localhost:${var.panel_port}/${local.effective_panel_slug}"
    subdomain_url    = var.enable_panel_subdomain && var.panel_domain != "" ? "https://${var.panel_domain}/${local.effective_panel_slug}" : null
    username         = var.panel_username
    password         = local.effective_panel_pass
    entrance         = local.effective_panel_slug
  }
}

output "managed_postgres" {
  description = "Connection details for the dedicated Linode Managed PostgreSQL cluster (if enabled)."
  sensitive   = true
  value = var.enable_managed_postgres ? {
    id             = linode_database_postgresql_v2.db[0].id
    host_primary   = linode_database_postgresql_v2.db[0].host_primary
    host_secondary = linode_database_postgresql_v2.db[0].host_secondary
    port           = linode_database_postgresql_v2.db[0].port
    username       = linode_database_postgresql_v2.db[0].root_username
    password       = linode_database_postgresql_v2.db[0].root_password
    ca_cert        = linode_database_postgresql_v2.db[0].ca_cert
    connection_uri = "postgres://${linode_database_postgresql_v2.db[0].root_username}:${urlencode(linode_database_postgresql_v2.db[0].root_password)}@${linode_database_postgresql_v2.db[0].host_primary}:${linode_database_postgresql_v2.db[0].port}/defaultdb?sslmode=require"
  } : null
}
