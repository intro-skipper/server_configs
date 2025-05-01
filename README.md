# Why?

Jellyfin currently has no way to limit the maximum ABI version. This means that people can install incompatible versions of a plugin. Unfortunately, the error is only visible after restarting Jellyfin. The average user expects to be offered only working and compatible versions.

## Apache Server with mod_rewrite 

Almost all webhosters have Apache `mod_rewrite` enabled. PHP always has restrictions and is not needed anyway.

## Cloudflare Domain Redirect Rules

> [!CAUTION]
> Some countries block Cloudflare

Instead of spending money for a webhoster you can connect a domain to cloudflare and use domain redirect rules.

Rules -> Redirect Rules

All rules are `Custom filter expressions`

| **Field**  | **Operator**    | **Value**               | **URL redirect Type** | **URL**                                                                                      | Status code |
|------------|-----------------|-------------------------|-----------------------|----------------------------------------------------------------------------------------------|-------------|
| User Agent | strict wildcard | Jellyfin-Server/10.10.* | Static                | <https://raw.githubusercontent.com/intro-skipper/intro-skipper/refs/heads/10.10/manifest.json> | 302         |
| User Agent | strict wildcard | Jellyfin-Server/10.9.*  | Static                | <https://raw.githubusercontent.com/intro-skipper/intro-skipper/refs/heads/10.9/manifest.json>  | 302         |
| User Agent | strict wildcard | Jellyfin-Server/10.8.*  | Static                | <https://raw.githubusercontent.com/intro-skipper/intro-skipper/refs/heads/10.8/manifest.json>  | 302         |

## Reserved IPv6 DigitalOcean

You can drop a small systemd-networkd-dispatcher hook:

1. **Create** `/etc/networkd-dispatcher/routable.d/10-custom-ipv6.sh`:
   ```bash
   #!/bin/sh
   ip -6 addr replace <IPV6>/128 dev lo scope global
   ip -6 route replace default dev eth0
   ```
2. **Make it executable**:
   ```bash
   chmod +x /etc/networkd-dispatcher/routable.d/10-custom-ipv6.sh
   ```
