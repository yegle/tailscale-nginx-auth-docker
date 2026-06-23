# tailscale-nginx-auth-docker

Automated packaging and multi-architecture container images for the Tailscale [nginx-auth](https://github.com/tailscale/tailscale/tree/main/cmd/nginx-auth) CLI.

## Purpose

This repository automates the compilation, packaging, and distribution of Tailscale's `nginx-auth` utility, which enables Nginx to authenticate requests using Tailscale node identities.

## Container Features

- **Multi-Architecture**: Built and published for both `linux/amd64` and `linux/arm64`.
- **Fast Build Times**: Uses native cross-compilation within the Docker builder stage to bypass slow QEMU emulation.
- **Secure and Minimal**: Uses Google's Distroless static base image (`gcr.io/distroless/static-debian12`), which contains only the essential OCI/SSL configurations and no shell or unnecessary packages.
- **Volume socket support**:
  - The container expects the Tailscale local daemon socket to be mounted at `/tailscale.sock`.
  - The `TS_SOCKET` environment variable inside the image is pre-configured to `/tailscale.sock`.

## CI/CD Automation

This repository includes two GitHub Action workflows:

1. **Build and Release** (`release.yml`):
   - Triggered on tag push matching `v*`.
   - Generates OCI metadata and tags.
   - Leverages GitHub Actions caching (`type=gha`) for incremental build speed.
   - Pushes build artifacts to GitHub Container Registry (GHCR) as `ghcr.io/yegle/tailscale-nginx-auth:<version>` and `ghcr.io/yegle/tailscale-nginx-auth:latest`.

2. **Upstream Tag Sync** (`sync-tags.yml`):
   - Runs on a nightly schedule (cron) and can be run manually.
   - Checks the upstream `tailscale/tailscale` repository for new release tags.
   - Automatically tags and pushes matching versions to this repository, triggering the release workflow.
