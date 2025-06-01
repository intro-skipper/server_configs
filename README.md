# Why?

Jellyfin currently has no way to limit the maximum ABI version. This means that people can install incompatible versions of a plugin. Unfortunately, the error is only visible after restarting Jellyfin. The average user expects to be offered only working and compatible versions.

## Caddy

The easiest method of self-hosting is to use Caddy, which is how we currently deploy on DigitalOcean.  See the `docker-compose.yaml` and `Caddyfile` for reference.

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
| User Agent | strict wildcard | Jellyfin-Server/10.10.* | Static                | <https://raw.githubusercontent.com/intro-skipper/manifest/refs/heads/main/10.10/manifest.json> | 302         |
| User Agent | strict wildcard | Jellyfin-Server/10.9.*  | Static                | <https://raw.githubusercontent.com/intro-skipper/manifest/refs/heads/main/10.9/manifest.json>  | 302         |
| User Agent | strict wildcard | Jellyfin-Server/10.8.*  | Static                | <https://raw.githubusercontent.com/intro-skipper/manifest/refs/heads/main/10.8/manifest.json>  | 302         |

## Reserved IPv6 DigitalOcean

Inspired by DigitalOcean Docs [Enable Reserved IPv6](https://docs.digitalocean.com/products/networking/reserved-ips/how-to/manually-enable/#enable-reserved-ipv6)

Our script generates and implements a permanent network plan.

```bash
curl -fsSL https://raw.githubusercontent.com/intro-skipper/server_configs/refs/heads/main/set_reserved_ipv6.sh | bash
```
