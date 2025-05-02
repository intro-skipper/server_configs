#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────
METADATA_URL="http://169.254.169.254/metadata/v1.json"
NETPLAN_FILE="/etc/netplan/50-custom.yaml"
TABLE_ID=100

# ─────────────────────────────────────────────────────
# Fetch metadata
# ─────────────────────────────────────────────────────
if ! md=$(curl -fsSL "${METADATA_URL}"); then
  echo "ERROR: cannot fetch metadata from ${METADATA_URL}" >&2
  exit 1
fi

# ─────────────────────────────────────────────────────
# Parse IPv6 reserved IP info
# ─────────────────────────────────────────────────────
ip6_active=$(jq -r '.reserved_ip.ipv6.active' <<<"${md}")
if [[ "${ip6_active}" != "true" ]]; then
  echo "IPv6 reserved IP is not active; nothing to do."
  exit 0
fi
rip6=$(jq -r '.reserved_ip.ipv6.ip_address' <<<"${md}")

# ─────────────────────────────────────────────────────
# Write netplan config with its own routing table + policy
# ─────────────────────────────────────────────────────
cat > "${NETPLAN_FILE}" <<EOF
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
      dhcp6: no
      accept-ra: true
      addresses:
        - ${rip6}/128
      routes:
        - to: ::/0
          via: "::"
          table: ${TABLE_ID}
      routing-policy:
        - from: ${rip6}/128
          table: ${TABLE_ID}
EOF

# Secure the Netplan file
chmod 600 "${NETPLAN_FILE}"
echo "Set permissions 600 on ${NETPLAN_FILE}"  

echo "Wrote ${NETPLAN_FILE}:"
echo "  • IPv6: ${rip6}/128"
echo "  • default route in table ${TABLE_ID}"
echo "  • routing-policy on eth0: from ${rip6} → table ${TABLE_ID}"
echo

# ─────────────────────────────────────────────────────
# Apply
# ─────────────────────────────────────────────────────
netplan apply
echo "netplan apply completed; IPv6 should now be up on eth0 using table ${TABLE_ID}"
