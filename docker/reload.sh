#!/bin/sh
# This script graceful reloads the Caddy server inside the docker container. Graceful means that caddy reloads its configuration with zero downtime.
# Warning: Only works on Linux
caddy_container_id=$(docker ps | grep caddy | awk '{print $1;}')
docker exec $caddy_container_id caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile