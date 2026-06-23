# tailscale-nginx-auth-docker

Automated packaging and multi-architecture container images for the Tailscale [nginx-auth](https://github.com/tailscale/tailscale/tree/main/cmd/nginx-auth) CLI.

## Purpose

This repository automates the compilation, packaging, and distribution of Tailscale's `nginx-auth` utility, which enables Nginx to authenticate requests using Tailscale node identities.

## Container Features

- **Multi-Architecture**: Built and published for both `linux/amd64` and `linux/arm64`.
- **Fast Build Times**: Uses native cross-compilation within the Docker builder stage with Buildx cache mounts (`--mount=type=cache`) to bypass slow QEMU emulation and speed up Go package downloads and compilation.
- **Secure and Minimal**: Uses Google's Distroless static base image (`gcr.io/distroless/static-debian12`), which contains only the essential OCI/SSL configurations and no shell or unnecessary packages.
- **Volume socket support**:
  - The container expects the Tailscale local daemon socket to be mounted at `/tailscale.sock`.
  - The `TS_SOCKET` environment variable inside the image is pre-configured to `/tailscale.sock`.

## CI/CD Automation

This repository includes three GitHub Action workflows:

1. **Build and Release** (`release.yml`):
   - Triggered on branch pushes matching `v*`.
   - Generates OCI compliant metadata and tags matching the version branch name.
   - Leverages GitHub Actions caching (`type=gha`) for incremental build speed.
   - Pushes build artifacts to GitHub Container Registry (GHCR) as `ghcr.io/yegle/tailscale-nginx-auth-docker:<version>` and `ghcr.io/yegle/tailscale-nginx-auth-docker:latest`.

2. **Upstream Tag Sync** (`sync-tags.yml`):
   - Runs on a nightly schedule (cron) and can be run manually.
   - Checks the upstream `tailscale/tailscale` repository for new release tags (starting from `v1.100.0`).
   - Automatically creates a new branch from `main` for every new version and pushes it to trigger the release workflow.

3. **Merge Main into Latest** (`merge-main.yml`):
   - Triggered automatically on every new push/commit to the `main` branch.
   - Identifies the latest version branch (e.g. <!-- LATEST_VERSION -->v1.100.0<!-- /LATEST_VERSION -->).
   - Creates a merge commit to bring changes from `main` into it (using `--ff` fast-forward) and pushes it to trigger a fresh release build.

## Usage

You can run the `nginx-auth` container by mounting your Tailscale socket:

```bash
docker run -d \
  --name tailscale-nginx-auth \
  -v /var/run/tailscale/tailscaled.sock:/tailscale.sock \
  -v /tmp:/tmp \
  ghcr.io/yegle/tailscale-nginx-auth-docker:<!-- LATEST_VERSION -->v1.100.0<!-- /LATEST_VERSION -->
```

By default, the container listens on the Unix socket at `/tmp/nginx-auth.sock` (corresponding to the `-v /tmp:/tmp` mount). You can configure your Nginx server to use this socket for Tailscale authentication.

If you wish to customize the socket location inside the container, you can pass the `-sockpath` argument:

```bash
docker run -d \
  --name tailscale-nginx-auth \
  -v /var/run/tailscale/tailscaled.sock:/tailscale.sock \
  -v /var/run/tailscale-nginx-auth:/var/run/tailscale-nginx-auth \
  ghcr.io/yegle/tailscale-nginx-auth-docker:<!-- LATEST_VERSION -->v1.100.0<!-- /LATEST_VERSION --> \
  -sockpath /var/run/tailscale-nginx-auth/nginx-auth.sock
```
