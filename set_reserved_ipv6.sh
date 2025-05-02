#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────
IFACE_ETH0="eth0"
IFACE_LO="lo"
PREFIX_LEN="128"

METADATA_URL="http://169.254.169.254/metadata/v1.json"
DISPATCHER_DIR="/etc/networkd-dispatcher/routable.d"
SCRIPT_NAME="10-custom-ipv6.sh"
SCRIPT_PATH="${DISPATCHER_DIR}/${SCRIPT_NAME}"

# ─────────────────────────────────────────────────────
# Fetch metadata
# ─────────────────────────────────────────────────────
if ! md=$(curl -fsSL "${METADATA_URL}"); then
    echo "ERROR: Cannot fetch metadata from ${METADATA_URL}" >&2
    exit 1
fi

# ─────────────────────────────────────────────────────
# Parse IPv6 reserved IP info
# ─────────────────────────────────────────────────────
# (jq -r will error if JSON is invalid)
ip6_active=$(jq -r '.reserved_ip.ipv6.active' <<<"${md}")
if [[ "${ip6_active}" != "true" ]]; then
    echo "IPv6 reserved IP is not active; nothing to do."
    exit 0
fi

rip6=$(jq -r '.reserved_ip.ipv6.ip_address' <<<"${md}")

# ─────────────────────────────────────────────────────
# Write dispatcher script atomically
# ─────────────────────────────────────────────────────
mkdir -p "${DISPATCHER_DIR}"
cat > "${SCRIPT_PATH}" <<EOF
#!/bin/sh
# auto-generated: apply reserved IPv6
ip -6 addr replace ${rip6}/${PREFIX_LEN} dev ${IFACE_LO} scope global
ip -6 route replace default dev ${IFACE_ETH0}
EOF

chmod +x "${SCRIPT_PATH}"
echo "Created default IPv6 route via ${IFACE_ETH0} (script: ${SCRIPT_PATH})"
