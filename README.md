# Why?

Jellyfin currently has no way to limit the maximum ABI version. This means that people can install incompatible versions of a plugin. Unfortunately, the error is only visible after restarting Jellyfin. The average user expects to be offered only working and compatible versions.

## Caddy

The easiest method of self-hosting is to use Caddy, which is how we currently deploy on DigitalOcean.  See the `docker-compose.yaml` and `Caddyfile` for reference.

All Jellyfin 12.x clients use the canonical `12/manifest.json` catalog. Jellyfin 10.x clients keep their minor-version catalogs, such as `10.11/manifest.json`. The manifest publisher keeps `12.0/manifest.json` and `12.0/manifest-prerelease.json` synchronized with their `12/` counterparts for existing direct URLs.

When migrating from `12.0/`, publish the new `12/` catalogs and updated publishing scripts first, so that `manifest@main` contains `12/manifest.json` before the Caddyfile is deployed. The `commit_hash` committed in this repo is only a placeholder: the deploy workflow replaces it with the current `manifest@main` commit, and the Caddyfile Updater keeps it in sync afterwards.

### Deploying the Caddyfile

Deployment is done by the **Deploy Caddyfile** GitHub Actions workflow ([`deploy-caddy.yml`](.github/workflows/deploy-caddy.yml)). It is triggered manually only:

1. Merge the Caddyfile change to `main`.
2. Actions → **Deploy Caddyfile** → *Run workflow* (branch `main`).

The workflow joins the tailnet with [tailscale/github-action](https://github.com/tailscale/github-action) as an ephemeral `tag:ci` node and, for each server (`fra`, `ams`, `germany`), over Tailscale SSH:

1. uploads `docker/Caddyfile` with `commit_hash` set to the current `intro-skipper/manifest@main` commit,
2. runs [`docker/deploy-remote.sh`](docker/deploy-remote.sh), which validates the new config inside the Caddy container (so `{env.*}` placeholders resolve), overwrites `/home/caddy/Caddyfile` in place and gracefully reloads Caddy,
3. finally runs the HTTPS redirect tests ([`test-caddy.yml`](.github/workflows/test-caddy.yml)) against the live servers.

An invalid Caddyfile fails the job before anything on disk changes. `/home/caddy/Caddyfile` is a single-file bind mount, so it must be overwritten in place, never replaced with `mv`.

The redirect tests only run as part of the deploy (or via *Run workflow*), since they test the deployed servers rather than the checked-out Caddyfile.

#### One-time setup

- Tailscale ACL: a `tagOwners` entry for `tag:ci`, an `acls`/`grants` rule allowing `tag:ci` → server tag on port 22, and an `ssh` rule (`action: accept`) allowing `tag:ci` to log in as `root`. Without the network rule the servers never show up in the runner's peer list and the workflow hangs on `ping`.
- A Tailscale OAuth client with the `auth_keys` write scope, tagged `tag:ci`.
- Repository secrets `TS_OAUTH_CLIENT_ID` and `TS_OAUTH_SECRET`.

#### Manual deploy

The same steps can be run by hand from a machine on the tailnet:

```bash
hash=$(git ls-remote https://github.com/intro-skipper/manifest.git refs/heads/main | cut -f1)
for h in fra ams germany; do
  sed "s/commit_hash \"[0-9a-f]*\"/commit_hash \"$hash\"/" docker/Caddyfile | ssh root@$h 'cat > /home/caddy/Caddyfile.new'
  ssh root@$h bash -s < docker/deploy-remote.sh
done
```

### Caddyfile Updater _(optional)_

We switched to [jsDelivr](https://www.jsdelivr.com/package/gh/intro-skipper/manifest) in oder to serve manifest and logo requests in without hitting GitHub API limits. [Caddyfile Updater](https://github.com/intro-skipper/go_caddy_url_updater) always serves the current version by updating the Caddyfile and reloading Caddy without any downtime.

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
| User Agent | strict wildcard | Jellyfin-Server/12.*    | Static                | <https://raw.githubusercontent.com/intro-skipper/manifest/refs/heads/main/12/manifest.json>    | 302         |
| User Agent | strict wildcard | Jellyfin-Server/10.11.* | Static                | <https://raw.githubusercontent.com/intro-skipper/manifest/refs/heads/main/10.11/manifest.json> | 302         |
| User Agent | strict wildcard | Jellyfin-Server/10.10.* | Static                | <https://raw.githubusercontent.com/intro-skipper/manifest/refs/heads/main/10.10/manifest.json> | 302         |
| User Agent | strict wildcard | Jellyfin-Server/10.9.*  | Static                | <https://raw.githubusercontent.com/intro-skipper/manifest/refs/heads/main/10.9/manifest.json>  | 302         |
| User Agent | strict wildcard | Jellyfin-Server/10.8.*  | Static                | <https://raw.githubusercontent.com/intro-skipper/manifest/refs/heads/main/10.8/manifest.json>  | 302         |

## Reserved IPv6 DigitalOcean

Inspired by DigitalOcean Docs [Enable Reserved IPv6](https://docs.digitalocean.com/products/networking/reserved-ips/how-to/manually-enable/#enable-reserved-ipv6)

Our script generates and implements a permanent network plan.

```bash
curl -fsSL https://raw.githubusercontent.com/intro-skipper/server_configs/refs/heads/main/set_reserved_ipv6.sh | bash
```
