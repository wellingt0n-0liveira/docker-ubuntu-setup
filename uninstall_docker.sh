#!/usr/bin/env bash
#
# Desinstalação completa do Docker Engine no Ubuntu (Clean Uninstall)
# - Para serviços, remove pacotes via purge, limpa dados, redes e chaves GPG
#
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}=================================================================${NC}"
echo -e "${RED}⚠️  INICIANDO DESINSTALAÇÃO COMPLETA DO DOCKER (IRREVERSÍVEL)${NC}"
echo -e "${RED}=================================================================${NC}"

# 1. Validação de privilégios
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Erro: Execute este script usando sudo ou como root.${NC}"
  exit 1
fi

echo -e "${YELLOW}🛑 [1/6] Parando serviços do Docker e Containerd...${NC}"
systemctl stop docker.service 2>/dev/null || true
systemctl stop docker.socket 2>/dev/null || true
systemctl stop containerd.service 2>/dev/null || true
systemctl disable docker.service 2>/dev/null || true
systemctl disable docker.socket 2>/dev/null || true

echo -e "${YELLOW}📦 [2/6] Removendo pacotes do Docker (purge)...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get purge -y -qq \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin \
  docker-ce-rootless-extras 2>/dev/null || true

apt-get autoremove -y -qq --purge

echo -e "${YELLOW}🗑️  [3/6] Apagando imagens, contêineres, volumes e redes...${NC}"
rm -rf /var/lib/docker
rm -rf /var/lib/containerd
rm -rf /var/run/docker.sock

echo -e "${YELLOW}🛡️  [4/6] Removendo configurações do daemon.json...${NC}"
rm -rf /etc/docker

echo -e "${YELLOW}🔑 [5/6] Removendo repositórios DEB822 e chaves GPG...${NC}"
rm -f /etc/apt/sources.list.d/docker.sources
rm -f /etc/apt/sources.list.d/docker.list
rm -f /etc/apt/keyrings/docker.asc
rm -f /etc/apt/keyrings/docker.gpg
apt-get update -qq

echo -e "${YELLOW}🗓️  [6/6] Removendo agendamentos Cron, logs e grupo docker...${NC}"
rm -f /etc/cron.d/docker-cleanup
rm -f /var/log/docker-cleanup.log
groupdel docker 2>/dev/null || true

echo -e "${GREEN}=================================================================${NC}"
echo -e "${GREEN}✅ Docker completamente removido e servidor limpo!${NC}"
echo -e "${GREEN}=================================================================${NC}"
