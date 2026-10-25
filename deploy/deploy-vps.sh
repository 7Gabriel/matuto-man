#!/usr/bin/env bash
# Roda NA VPS, como usuário deploy, chamado pelo workflow via SSH:  bash -s -- <imagem:tag> <dominio_jogo>
# 1) grava DOMINIO_JOGO no .env do Analisador (o Caddy de borda lê de lá)
# 2) sobe/atualiza o container matuto-man na rede do compose do Analisador
# 3) recria o Caddy de borda se a variável mudou, para ele emitir o certificado do domínio
set -euo pipefail
IMAGEM="${1:?imagem:tag}"
DOMINIO="${2:?dominio do jogo}"
BORDA=/opt/analisador
REDE=analisador_default

[[ "$DOMINIO" =~ ^([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,}$ ]] || { echo "Domínio inválido: $DOMINIO"; exit 1; }
docker network inspect "$REDE" >/dev/null 2>&1 || { echo "Rede $REDE não existe: o Analisador precisa estar no ar nesta VM."; exit 1; }

echo "== Imagem $IMAGEM"
docker pull -q "$IMAGEM"

echo "== Container matuto-man"
docker rm -f matuto-man >/dev/null 2>&1 || true
docker run -d --name matuto-man --restart unless-stopped \
  --network "$REDE" --memory 64m --read-only --tmpfs /config --tmpfs /data \
  --label app=matuto-man --label imagem="$IMAGEM" "$IMAGEM" >/dev/null
for i in $(seq 1 20); do
  st=$(docker inspect -f '{{.State.Health.Status}}' matuto-man 2>/dev/null || echo starting)
  [ "$st" = healthy ] && break; sleep 2
done
[ "$st" = healthy ] || { echo "Container não ficou saudável:"; docker logs --tail 30 matuto-man; exit 1; }

echo "== Caddy de borda"
cd "$BORDA"
ATUAL=$(grep -E '^DOMINIO_JOGO=' .env | cut -d= -f2- || true)
if [ "$ATUAL" != "$DOMINIO" ]; then
  cp .env ".env.antes-jogo.$(date +%s)"
  grep -q '^DOMINIO_JOGO=' .env && sed -i "s|^DOMINIO_JOGO=.*|DOMINIO_JOGO=$DOMINIO|" .env || echo "DOMINIO_JOGO=$DOMINIO" >> .env
  docker compose up -d --no-deps web
  echo "Caddy recriado com DOMINIO_JOGO=$DOMINIO"
else
  echo "DOMINIO_JOGO já era $DOMINIO; Caddy mantido."
fi

echo "== Teste de ponta a ponta"
for i in $(seq 1 12); do
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "https://$DOMINIO/" || true)
  [ "$code" = 200 ] && { echo "https://$DOMINIO respondeu 200. No ar."; docker image prune -f >/dev/null; exit 0; }
  sleep 10
done
echo "https://$DOMINIO ainda não respondeu 200 (último código: ${code:-nenhum}). Veja: docker compose -f $BORDA/docker-compose.yml logs web --tail 50"
exit 1
