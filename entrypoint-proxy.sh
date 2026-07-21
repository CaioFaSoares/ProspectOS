#!/bin/sh
# Gera o hash bcrypt em tempo de execução a partir de BASIC_AUTH_PASSWORD (texto
# puro) - evita guardar/colar um hash com "$" em UIs/arquivos .env, que quebra
# fácil por causa do escaping de "$" do docker-compose (já mordemos essa duas
# vezes: local e no Coolify).
set -e
export BASIC_AUTH_HASH="$(caddy hash-password --plaintext "$BASIC_AUTH_PASSWORD")"
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
