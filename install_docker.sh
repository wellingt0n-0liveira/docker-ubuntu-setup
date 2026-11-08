#!/usr/bin/env bash
#
# Instalação profissional do Docker Engine em Ubuntu (Full Production)
# - Usa o formato moderno DEB822 (.sources)
# - Configura chave GPG no formato .asc
# - Aplica boas práticas de segurança e manutenção
#
set -euo pipefail

# Cores para melhor legibilidade
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=================================================================${NC}"
echo -e "${GREEN}🚀 Iniciando instalação profissional do Docker (Full Production)${NC}"
echo -e "${GREEN}=================================================================${NC}"

# 1. Validação de privilégios
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Erro: Execute este script usando sudo (ex: curl -fsSL URL | sudo bash)${NC}"
  exit 1
fi

REAL_USER=${SUDO_USER:-$USER}

echo -e "${YELLOW}🧹 [1/8] Removendo versões antigas ou conflitantes...${NC}"
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc docker-engine; do
  apt-get remove -y "$pkg" 2>/dev/null || true
done

# Remove arquivos de repositório antigos para evitar conflitos
rm -f /etc/apt/sources.list.d/docker.list
rm -f /etc/apt/keyrings/docker.gpg

echo -e "${YELLOW}📦 [2/8] Atualizando sistema e instalando dependências...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
# Nota: gnupg não é mais necessário, pois usaremos a chave .asc diretamente
apt-get install -y -qq ca-certificates curl

echo -e "${YELLOW}🔑 [3/8] Configurando chave GPG oficial do Docker...${NC}"
install -m 0755 -d /etc/apt/keyrings
# Baixa a chave no formato .asc (recomendado oficialmente)
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo -e "${YELLOW}📝 [4/8] Configurando repositório no formato DEB822...${NC}"
ARCH=$(dpkg --print-architecture)
# Detecta o codename de forma robusta (UBUNTU_CODENAME ou VERSION_CODENAME)
CODENAME=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")

cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${CODENAME}
Components: stable
Architectures: ${ARCH}
Signed-By: /etc/apt/keyrings/docker.asc
EOF
chmod 0644 /etc/apt/sources.list.d/docker.sources

echo -e "${YELLOW}⚙️ [5/8] Instalando Docker Engine, CLI e plugins...${NC}"
apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo -e "${YELLOW}🛡️ [6/8] Aplicando configurações de produção no daemon.json...${NC}"
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-address-pools": [
    {
      "base": "172.28.0.0/16",
      "size": 24
    }
  ],
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true
}
EOF

echo -e "${YELLOW}🗓️ [7/8] Configurando limpeza semanal automática (Cron)...${NC}"
cat > /etc/cron.d/docker-cleanup <<EOF
# Limpa imagens não utilizadas, redes órfãs e cache de build todo domingo às 03:00
0 3 * * 0 root /usr/bin/docker system prune -af --filter "until=168h" > /var/log/docker-cleanup.log 2>&1
EOF
chmod 0644 /etc/cron.d/docker-cleanup

echo -e "${YELLOW}👤 [8/8] Configurando permissões, reiniciando e validando...${NC}"
systemctl daemon-reload
systemctl enable --now docker
systemctl restart docker

groupadd -f docker
if [ "$REAL_USER" != "root" ]; then
  usermod -aG docker "$REAL_USER"
fi

# Validações finais
echo -e "${YELLOW}🧪 Executando testes de validação...${NC}"
docker --version
docker compose version
docker info --format 'Driver de Log Ativo: {{.LoggingDriver}}'

# Teste de rede
docker network create teste-subnet > /dev/null
SUBNET_CRIADA=$(docker network inspect teste-subnet --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}')
docker network rm teste-subnet > /dev/null
echo -e "${GREEN}Faixa de Rede Validada: $SUBNET_CRIADA${NC}"

# Verifica cron e executa hello-world
test -f /etc/cron.d/docker-cleanup && echo -e "${GREEN}Agendamento Cron: Ativo (/etc/cron.d/docker-cleanup)${NC}"
docker run --rm hello-world > /dev/null

echo -e "${GREEN}=================================================================${NC}"
echo -e "${GREEN}✅ Ambiente Docker configurado e validado para produção!${NC}"
if [ "$REAL_USER" != "root" ]; then
  echo -e "${YELLOW}⚠️  IMPORTANTE: Para usar o docker sem 'sudo' neste terminal, rode:${NC}"
  echo -e "    newgrp docker"
fi
echo -e "${GREEN}=================================================================${NC}"
