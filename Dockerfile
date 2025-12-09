# Tide Gateway - Docker Container
# ================================
# Tor SOCKS5 proxy and DNS resolver in a container.
#
# Usage:
#   docker run -d --name tide -p 9050:9050 -p 5353:5353 bodegga/tide
#
# Then configure apps to use:
#   SOCKS5 proxy: localhost:9050
#   DNS: localhost:5353

FROM alpine:3.21

RUN apk add --no-cache tor && \
    mkdir -p /var/lib/tor && \
    chown -R tor:tor /var/lib/tor

COPY torrc /etc/tor/torrc

USER tor
EXPOSE 9050 5353

CMD ["tor", "-f", "/etc/tor/torrc"]
