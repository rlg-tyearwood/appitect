#!/usr/bin/env bash
# Day-2 synchronization script: updates Caddy + Coraza WAF config on an existing dedicated VPS
# without reprovisioning the Linode instance.
# Usage: ./scripts/sync-edge.sh <VPS_IP> <RENDERED_CADDYFILE_PATH>
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <vps_ip> <rendered_caddyfile_path>"
  exit 1
fi

VPS_IP="$1"
CADDYFILE_PATH="$2"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

scp "${REPO_ROOT}/edge/Dockerfile.caddy" "${REPO_ROOT}/edge/docker-compose.yml" "deploy@${VPS_IP}:/opt/appitect/edge/"
scp "${CADDYFILE_PATH}" "deploy@${VPS_IP}:/opt/appitect/edge/Caddyfile"

ssh "deploy@${VPS_IP}" <<'EOF'
set -euo pipefail
cd /opt/appitect/edge
docker compose up -d --build
docker exec appitect-caddy caddy validate --config /etc/caddy/Caddyfile
docker exec appitect-caddy caddy reload --config /etc/caddy/Caddyfile
EOF

echo "Edge Caddy + Coraza OWASP WAF configuration synced and reloaded on ${VPS_IP}."
