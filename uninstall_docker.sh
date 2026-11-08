#!/usr/bin/env bash
#
# Desinstalação completa e limpeza do Docker Engine em Ubuntu
#
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}=================================================================${NC}"
echo -e "${RED}⚠️  Iniciando desinstalação completa do Docker${NC}"
echo -e "${RED}=================================================================${NC}"

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Erro: Execute este script usando sudo${NC}"
  exit 1
fi

REAL_USER=${SUDO_USER:-$USER}

echo -e "${YELLOW}🛑 [1/5] Parando serviços e removendo contêineres ativos...${NC}"
systemctl stop docker.socket docker.service containerd.service 2>/dev/null || true
systemctl disable docker.socket docker.service containerd.service 2>/dev/null || true

echo -e "${YELLOW}📦 [2/5] Desinstalando pacotes do Docker...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get purge -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras 2>/dev/null || true
apt-get autoremove -y -qq --purge

echo -e "${YELLOW}🗑️ [3/5] Removendo imagens, volumes, redes e configurações...${NC}"
rm -rf /var/lib/docker
rm -rf /var/lib/containerd
rm -rf /etc/docker
rm -f /var/run/docker.sock

echo -e "${YELLOW}🔑 [4/5] Removendo repositórios, chaves GPG e agendamentos Cron...${NC}"
rm -f /etc/apt/sources.list.d/docker.sources
rm -f /etc/apt/sources.list.d/docker.list
rm -f /etc/apt/keyrings/docker.asc
rm -f /etc/apt/keyrings/docker.gpg
rm -f /etc/cron.d/docker-cleanup
rm -f /var/log/docker-cleanup.log

echo -e "${YELLOW}👤 [5/5] Removendo grupo docker e atualizando apt...${NC}"
if [ "$REAL_USER" != "root" ] && id -nG "$REAL_USER" | grep -qw "docker"; then
  gpasswd -d "$REAL_USER" docker 2>/dev/null || true
fi
groupdel docker 2>/dev/null || true
apt-get update -qq

echo -e "${GREEN}=================================================================${NC}"
echo -e "${GREEN}✅ Docker e todos os seus dados foram removidos do sistema!${NC}"
echo -e "${GREEN}=================================================================${NC}"
