# Stage 1: Build
FROM --platform=$BUILDPLATFORM golang:1.26 AS builder

# Install git
RUN apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*

# Build argument for the tailscale version/ref to checkout
ARG TAILSCALE_VERSION=main

WORKDIR /src

# Clone the Tailscale repository and checkout the specific version
RUN git clone --depth 1 --branch ${TAILSCALE_VERSION} https://github.com/tailscale/tailscale.git . || \
    (git clone https://github.com/tailscale/tailscale.git . && git checkout ${TAILSCALE_VERSION})

# Cross-compilation variables automatically set by Docker Buildx
ARG TARGETOS
ARG TARGETARCH

# Build the nginx-auth binary for the target architecture with cache mounts
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -ldflags "-s -w" -o /app/nginx-auth ./cmd/nginx-auth

# Stage 2: Runtime
# Use Google's distroless static image, which contains ca-certificates, passwd, tzdata, etc.
FROM gcr.io/distroless/static-debian12

# Copy the binary from the builder stage to the root folder
COPY --from=builder /app/nginx-auth /nginx-auth

# Declare the tailscale.sock file mount requirement at /tailscale.sock
VOLUME ["/tailscale.sock"]

# Configure Tailscale client to use the socket at /tailscale.sock
ENV TS_SOCKET=/tailscale.sock

# Set the ENTRYPOINT to the binary in the root folder
ENTRYPOINT ["/nginx-auth"]
CMD ["-sockpath", "/tmp/nginx-auth.sock"]
