# 🐳 Docker Ubuntu Setup (Full Production)

Script automatizado e idempotente para instalação e configuração profissional do **Docker Engine** e **Docker Compose** em servidores Ubuntu, aplicando boas práticas de segurança, rede e manutenção.

## 🚀 Instalação Rápida (Linha Única)

Execute o comando abaixo no terminal do seu servidor Ubuntu para baixar, instalar, configurar e validar todo o ambiente automaticamente sem intervenção:

```bash
curl -fsSL https://githubusercontent.com | sudo bash && newgrp docker
```

> **Nota:** Caso seu usuário exija senha para comandos `sudo`, ela será solicitada apenas uma vez no início da execução.

---

## ⚙️ O que este script configura

1. **Limpeza de Conflitos:** Remove versões antigas ou não oficiais (`docker.io`, `podman-docker`, `containerd`, etc.) e limpa repositórios legados.
2. **Repositório Oficial Moderno:** Configura a chave GPG `.asc` e o repositório oficial do Docker no formato **DEB822** (`/etc/apt/sources.list.d/docker.sources`).
3. **Pacotes Instalados:** Instala `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin` e `docker-compose-plugin`.
4. **Hardening e Produção (`/etc/docker/daemon.json`):**
   * **Rotação de Logs:** Limita os logs a `10MB` por arquivo com retenção máxima de `3` arquivos por contêiner (evitando lotação de disco).
   * **Isolamento de Rede:** Define o pool de IPs internos para `172.28.0.0/16` (sub-redes `/24`), prevenindo conflitos com redes locais e VPNs corporativas.
   * **Segurança e Disponibilidade:** Ativa `live-restore: true` (mantém contêineres vivos durante atualizações do daemon), `no-new-privileges: true` e desativa o `userland-proxy`.
5. **Manutenção Automática (`Cron`):** Agenda uma limpeza semanal (`/etc/cron.d/docker-cleanup`) todo domingo às 03:00 para remover imagens e caches órfãos com mais de 7 dias (`168h`), preservando volumes de dados.
6. **Permissões Pós-Instalação:** Adiciona o usuário atual ao grupo `docker` para execução de comandos sem `sudo`.
7. **Validação Automática:** Testa as versões instaladas, driver de log, criação de sub-rede e executa um contêiner `hello-world` temporário.

---

## 📋 Requisitos

* Ubuntu (20.04 LTS, 22.04 LTS, 24.04 LTS ou superior)
* Acesso à internet e privilégios de `sudo`
* Pacote `curl` instalado
