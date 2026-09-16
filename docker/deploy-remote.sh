#!/bin/bash
# Runs ON the server (piped in via `ssh root@host bash -s < docker/deploy-remote.sh`).
# Expects the new config at /home/caddy/Caddyfile.new. Validates it inside the
# Caddy container (so {env.*} placeholders resolve), then installs and reloads.
set -euo pipefail

CONTAINER=caddy-caddy-1
UPDATER=go_caddy_url_updater
NEW=/home/caddy/Caddyfile.new
LIVE=/home/caddy/Caddyfile

docker cp "$NEW" "$CONTAINER:/tmp/Caddyfile.new"
docker exec "$CONTAINER" caddy validate --config /tmp/Caddyfile.new --adapter caddyfile

# The updater rewrites $LIVE on manifest webhooks; pause it so it cannot write
# while we replace the file. Its listening socket keeps queueing connections
# while paused, so a webhook arriving now is only delayed, not lost.
if [ "$(docker inspect -f '{{.State.Running}}' "$UPDATER" 2>/dev/null)" = "true" ]; then
	docker pause "$UPDATER" >/dev/null
	trap 'docker unpause "$UPDATER" >/dev/null' EXIT
fi

# $LIVE is a single-file bind mount into the container: replacing the inode (mv)
# would leave the container pointing at the old file, so overwrite in place.
cat "$NEW" > "$LIVE"
rm -f "$NEW"

docker exec "$CONTAINER" caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile
