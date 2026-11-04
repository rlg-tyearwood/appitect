variable "linode_token" {
  description = "Linode APIv4 Personal Access Token (optional if the LINODE_TOKEN environment variable is set)."
  type        = string
  default     = null
  sensitive   = true
}

variable "app_slug" {
  description = "Short lowercase identifier for the dedicated application (e.g. 'medial', 'progression'). Used in resource labels, directories, and Docker network names."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,19}$", var.app_slug))
    error_message = "app_slug must be 2-20 lowercase alphanumeric characters or hyphens, starting with a letter."
  }
}

variable "environment" {
  description = "Deployment environment name (e.g. 'production', 'staging')."
  type        = string
  default     = "production"
}

variable "linode_region" {
  description = "Linode datacenter region (e.g. 'us-east', 'us-mia', 'eu-central')."
  type        = string
  default     = "us-east"
}

variable "vps_type" {
  description = "Linode instance plan ID for the dedicated VPS (e.g. 'g6-standard-2' for 4GB RAM / 2 vCPUs)."
  type        = string
  default     = "g6-standard-2"
}

variable "vps_image" {
  description = "Linode OS image ID. Must support cloud-init via Linode Metadata."
  type        = string
  default     = "linode/ubuntu24.04"
}

variable "backups_enabled" {
  description = "Enable Linode automated daily/weekly VPS backups."
  type        = bool
  default     = true
}

variable "ssh_public_key" {
  description = "OpenSSH public key injected for both root and the 'deploy' CI/CD user."
  type        = string
}

variable "ssh_allowed_ipv4" {
  description = "IPv4 CIDR blocks permitted to reach SSH port 22 through the Linode Cloud Firewall."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ssh_allowed_ipv6" {
  description = "IPv6 CIDR blocks permitted to reach SSH port 22 through the Linode Cloud Firewall."
  type        = list(string)
  default     = ["::/0"]
}

variable "acme_email" {
  description = "Email address used by Caddy for Let's Encrypt ACME TLS certificate notifications."
  type        = string
}

variable "app_domain" {
  description = "Primary FQDN routed through Caddy + Coraza WAF to the dedicated application (e.g. 'app.example.com')."
  type        = string
}

variable "app_upstream_container" {
  description = "Container name of the public-facing web/BFF service on the 'vps_edge' Docker network (e.g. 'medialapp')."
  type        = string
}

variable "app_upstream_port" {
  description = "Internal container port exposed by app_upstream_container (e.g. 3000)."
  type        = number
  default     = 3000
}

variable "waf_mode" {
  description = "Coraza OWASP CRS rule engine mode: 'On' (actively block attacks) or 'DetectionOnly' (log only)."
  type        = string
  default     = "On"

  validation {
    condition     = contains(["On", "DetectionOnly"], var.waf_mode)
    error_message = "waf_mode must be either 'On' or 'DetectionOnly'."
  }
}

variable "max_body_mb" {
  description = "Maximum HTTP request body size in megabytes enforced by both Caddy and Coraza WAF."
  type        = number
  default     = 10
}

variable "panel_port" {
  description = "Internal host port for the 1Panel management UI (not opened on the public firewall by default)."
  type        = number
  default     = 10086
}

variable "panel_username" {
  description = "Administrator username for 1Panel."
  type        = string
  default     = "paneladmin"
}

variable "panel_password" {
  description = "Administrator password for 1Panel. Leave empty to generate a strong random password automatically."
  type        = string
  default     = ""
  sensitive   = true
}

variable "panel_entrance" {
  description = "Secret URL path entrance for 1Panel. Leave empty to generate a random 12-character slug automatically."
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_panel_subdomain" {
  description = "Expose 1Panel over HTTPS via Caddy on var.panel_domain (otherwise access securely via SSH port forwarding)."
  type        = bool
  default     = false
}

variable "panel_domain" {
  description = "Subdomain FQDN for 1Panel when enable_panel_subdomain is true (e.g. 'panel.example.com')."
  type        = string
  default     = ""
}

variable "enable_managed_postgres" {
  description = "Provision a dedicated Linode Managed PostgreSQL cluster in the same region, IP-allowlisted exclusively to this VPS."
  type        = bool
  default     = false
}

variable "postgres_engine_id" {
  description = "Linode Managed PostgreSQL engine ID (format: 'postgresql/<major_version>')."
  type        = string
  default     = "postgresql/16"
}

variable "postgres_node_type" {
  description = "Linode plan ID for Managed PostgreSQL nodes (e.g. 'g6-nanode-1', 'g6-dedicated-2')."
  type        = string
  default     = "g6-nanode-1"
}

variable "postgres_cluster_size" {
  description = "Number of nodes in the Managed PostgreSQL cluster (1 for standalone, 3 for High Availability)."
  type        = number
  default     = 1

  validation {
    condition     = contains([1, 3], var.postgres_cluster_size)
    error_message = "postgres_cluster_size must be 1 or 3."
  }
}

variable "postgres_extra_allow_cidrs" {
  description = "Optional extra IPv4/IPv6 CIDR blocks allowed to connect to Managed PostgreSQL in addition to the dedicated VPS."
  type        = list(string)
  default     = []
}
