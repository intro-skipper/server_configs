#!/usr/bin/env bash

set -euo pipefail

API_URL="https://api.github.com/meta"
TMP_JSON="/tmp/github_meta.json"

# --- Helper function ---
fail() {
  echo "[ERROR] $1" >&2
  exit 1
}

echo "[*] Fetching GitHub hook IP ranges..."

# --- Fetch with full error handling ---
HTTP_CODE=$(curl \
  -w "%{http_code}" \
  -o "$TMP_JSON" \
  -s --fail \
  --max-time 10 \
  "$API_URL") || fail "Network error reaching GitHub (timeout, DNS failure, or connection refused)."

if [[ "$HTTP_CODE" != "200" ]]; then
  fail "GitHub API returned HTTP $HTTP_CODE — aborting to avoid unsafe firewall changes."
fi

# --- Validate JSON structure ---
if ! jq -e '.hooks' "$TMP_JSON" >/dev/null 2>&1; then
  fail "GitHub API response missing 'hooks' field — API format changed? Aborting."
fi

CURRENT_HOOK_IPS=$(jq -r '.hooks[]' "$TMP_JSON")

if [[ -z "$CURRENT_HOOK_IPS" ]]; then
  fail "'hooks' list is empty — refusing to modify firewall."
fi

echo "[*] GitHub hook IPs retrieved:"
echo "$CURRENT_HOOK_IPS"
echo

# --- Get existing UFW rules matching these IP formats ---
EXISTING_IPS=$(sudo ufw status numbered | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]+)?|([0-9a-fA-F:]+:+)+[0-9a-fA-F:]+(::)?(/[0-9]+)?' | sort -u)

echo "[*] Existing UFW IPs:"
echo "$EXISTING_IPS"
echo

############################################
# REMOVE OUTDATED RULES
############################################
echo "[*] Searching for outdated rules..."

for rule_ip in $EXISTING_IPS; do
  if ! echo "$CURRENT_HOOK_IPS" | grep -qx "$rule_ip"; then
    echo "[!] Outdated GitHub IP detected: $rule_ip"

    # Find current number (UFW renumbers rules dynamically)
    RULE_NUM=$(timeout 10 sudo ufw status numbered | grep "$rule_ip" | awk -F'[][]' '{print $2}') || {
      echo "[ERROR] Timeout while reading UFW rules — aborting."
      exit 1
    }

    if [[ -n "$RULE_NUM" ]]; then
      echo "[*] Deleting rule $RULE_NUM for $rule_ip..."
      sudo ufw --force delete "$RULE_NUM"
    fi
  fi
done

############################################
# ADD NEW RULES
############################################
echo
echo "[*] Adding missing GitHub IP rules..."

for ip in $CURRENT_HOOK_IPS; do
  if echo "$EXISTING_IPS" | grep -qx "$ip"; then
    echo "[=] Rule already exists for $ip — OK."
  else
    echo "[+] Adding UFW allow rule for $ip..."
    sudo ufw allow from "$ip"
  fi
done

############################################
# Finalize
############################################
echo
echo "[*] Reloading UFW..."
sudo ufw reload

echo "[✓] Sync complete — GitHub webhook IPs are now up to date."