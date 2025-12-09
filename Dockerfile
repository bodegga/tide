# Tide Gateway - Secure Tor Container
# ====================================
# Minimal attack surface. Runs as non-root.
# 
# Usage:
#   docker run -d --name tide -p 9050:9050 -p 5353:5353/udp bodegga/tide
#
# Configure apps:
#   SOCKS5: localhost:9050
#   DNS:    localhost:5353

FROM alpine:3.21 AS base

# Install only what we need
RUN apk add --no-cache tor ca-certificates && \
    rm -rf /var/cache/apk/* /tmp/*

# Create minimal torrc
RUN mkdir -p /etc/tor /var/lib/tor /var/log/tor && \
    chown -R tor:tor /var/lib/tor /var/log/tor

COPY --chown=tor:tor torrc /etc/tor/torrc

# Run as tor user (non-root)
USER tor

# Health check - verify Tor is accepting connections
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD nc -z 127.0.0.1 9050 || exit 1

EXPOSE 9050 5353/tcp 5353/udp

CMD ["tor", "-f", "/etc/tor/torrc"]
