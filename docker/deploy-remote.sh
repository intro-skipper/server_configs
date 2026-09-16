#!/bin/bash
# Runs ON the server (piped in via `ssh root@host bash -s < docker/deploy-remote.sh`).
# Expects the new config at /home/caddy/Caddyfile.new. Validates it inside the
# Caddy container (so {env.*} placeholders resolve), then installs and reloads.
set -euo pipefail

CONTAINER=caddy-caddy-1
NEW=/home/caddy/Caddyfile.new
LIVE=/home/caddy/Caddyfile

docker cp "$NEW" "$CONTAINER:/tmp/Caddyfile.new"
docker exec "$CONTAINER" caddy validate --config /tmp/Caddyfile.new --adapter caddyfile

# $LIVE is a single-file bind mount into the container: replacing the inode (mv)
# would leave the container pointing at the old file, so overwrite in place.
cat "$NEW" > "$LIVE"
rm -f "$NEW"

docker exec "$CONTAINER" caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile
