#!/usr/bin/env bash

# Aborta a execução imediatamente se qualquer comando falhar
set -euo pipefail

echo "================================================================="
echo "🚀 Iniciando instalação profissional do Docker (Full Production)"
echo "================================================================="

# 1. Validação de privilégios
if [ "$EUID" -ne 0 ]; then
  echo "❌ Erro: Execute este script usando sudo (ex: curl -fsSL URL | sudo bash)"
  exit 1
fi

REAL_USER=${SUDO_USER:-$USER}

echo "🧹 [1/8] Removendo versões antigas ou conflitantes..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  apt-get remove -y "$pkg" 2>/dev/null || true
done

echo "📦 [2/8] Atualizando sistema e instalando dependências..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq ca-certificates curl gnupg lsb-release

echo "🔑 [3/8] Configurando chave GPG e repositório oficial do Docker..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://docker.com | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

ARCH=$(dpkg --print-architecture)
CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")

echo \
  "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] https://docker.com \
  $CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "⚙️ [4/8] Instalando Docker Engine, CLI e Docker Compose..."
apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "📝 [5/8] Configurando rotação de logs e pool de IPs no daemon.json..."
mkdir -p /etc/docker
cat <<EOF > /etc/docker/daemon.json
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
  ]
}
EOF

echo "🗓️ [6/8] Configurando limpeza semanal automática (Cron)..."
cat <<EOF > /etc/cron.d/docker-cleanup
# Limpa imagens não utilizadas, redes órfãs e cache de build todo domingo às 03:00
0 3 * * 0 root /usr/bin/docker system prune -af --filter "until=168h" > /var/log/docker-cleanup.log 2>&1
EOF
chmod 0644 /etc/cron.d/docker-cleanup

echo "👤 [7/8] Configurando permissões e reiniciando serviço..."
systemctl daemon-reload
systemctl enable --now docker
systemctl restart docker

groupadd -f docker
if [ "$REAL_USER" != "root" ]; then
  usermod -aG docker "$REAL_USER"
fi

echo "🧪 [8/8] Validando instalação, logs, rede e cron..."
docker --version
docker compose version
docker info --format 'Driver de Log Ativo: {{.LoggingDriver}}'
docker network create teste-subnet > /dev/null
SUBNET_CRIADA=$(docker network inspect teste-subnet --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}')
docker network rm teste-subnet > /dev/null
echo "Faixa de Rede Validada: $SUBNET_CRIADA"
test -f /etc/cron.d/docker-cleanup && echo "Agendamento Cron: Ativo (/etc/cron.d/docker-cleanup)"
docker run --rm hello-world > /dev/null

echo "================================================================="
echo "✅ Ambiente Docker configurado e validado para produção!"
if [ "$REAL_USER" != "root" ]; then
  echo "⚠️  IMPORTANTE: Para usar o docker sem 'sudo' neste terminal, rode:"
  echo "    newgrp docker"
fi
echo "================================================================="
