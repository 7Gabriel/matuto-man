FROM caddy:2-alpine
COPY Caddyfile /etc/caddy/Caddyfile
COPY site /srv
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://127.0.0.1/ | grep -q Matuto || exit 1
