# Matuto-Man

Jogo estilo Pac-Man em que o logo do **Matuto Programador** come bits e foge dos bugs: NullPointer, Deadlock, Legacy e Deploy na Sexta. Um único `site/index.html`, sem dependências.

## Rodar local
Abra `site/index.html` no navegador, ou `docker build -t matuto-man . && docker run -p 8080:80 matuto-man`.

## Deploy
`push` na `main` → GitHub Actions constrói a imagem (`ghcr.io/7gabriel/matuto-man`), publica e atualiza o container na VPS por SSH (`deploy/deploy-vps.sh`). O TLS e o domínio ficam com o Caddy de borda do repo `analisador-simetria-facial`, que faz `reverse_proxy matuto-man:80`.

Configuração do repositório:
- **Variável** `DOMINIO_JOGO`: domínio do jogo (registro A → IP da VPS).
- **Segredo** `VPS_SSH_KEY`: chave privada ed25519 autorizada no usuário `deploy` da VPS (workflow *Autorizar chave de deploy* do repo do Analisador).

## Controles
Setas ou WASD · `P` pausa · `Enter` começa · no celular, swipe ou d-pad.
