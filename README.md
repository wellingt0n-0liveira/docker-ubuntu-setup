# 🐳 Docker Ubuntu Setup (Full Production)

Script automatizado e idempotente para instalação e configuração profissional do **Docker Engine** e **Docker Compose** em servidores Ubuntu, aplicando boas práticas de segurança, rede e manutenção.

## 🚀 Instalação Rápida (Linha Única)

Escolha o comando correspondente ao seu usuário atual no servidor para baixar, instalar, configurar e validar todo o ambiente automaticamente sem intervenção:

* **Usuário Comum (com privilégios `sudo`):**
  ```bash
  curl -fsSL https://raw.githubusercontent.com/wellingt0n-0liveira/docker-ubuntu-setup/refs/heads/main/install_docker.sh | sudo bash
  ```
  > *Nota: Caso seu usuário exija senha para comandos `sudo`, ela será solicitada apenas uma vez no início da execução.*

* **Usuário `root` (direto no terminal administrativo):**
  ```bash
  curl -fsSL https://raw.githubusercontent.com/wellingt0n-0liveira/docker-ubuntu-setup/refs/heads/main/install_docker.sh | bash
  ```

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
* Acesso à internet e privilégios de `sudo` ou `root`
* Pacote `curl` instalado

---

## 🧪 Teste Automatizado do Ambiente (Low-Resource / Raspberry Pi)

Para validar se o Docker Compose, o isolamento de rede (`172.28.0.0/16`) e os limites de recursos estão operando corretamente — mesmo em máquinas limitadas como um **Raspberry Pi** — execute o comando abaixo:

* **Usuário Comum (sem precisar relogar ou digitar `sudo`):**
  ```bash
  mkdir -p ~/teste-docker && cd ~/teste-docker && curl -fsSLO https://raw.githubusercontent.com/wellingt0n-0liveira/docker-ubuntu-setup/refs/heads/main/docker-compose.yml && sg docker -c "docker compose up -d && sleep 3 && docker ps --filter 'name=app-web-teste'"
  ```

* **Usuário `root`:**
  ```bash
  mkdir -p ~/teste-docker && cd ~/teste-docker && curl -fsSLO https://raw.githubusercontent.com/wellingt0n-0liveira/docker-ubuntu-setup/refs/heads/main/docker-compose.yml && docker compose up -d && sleep 3 && docker ps --filter "name=app-web-teste"
  ```

* **Características do contêiner de teste:** Utiliza a imagem `busybox:1.36-musl` (< 2 MB), roda com sistema de arquivos somente leitura (`read_only: true`), sem privilégios de kernel (`cap_drop: ALL`) e teto máximo de **32 MB de RAM**.

### 🧹 Limpar o Ambiente de Teste

Para encerrar e remover completamente o contêiner, a rede e a pasta temporária após validar:

* **Usuário Comum:**
  ```bash
  sg docker -c "docker compose down" && cd ~ && rm -rf ~/teste-docker
  ```

* **Usuário `root`:**
  ```bash
  docker compose down && cd ~ && rm -rf ~/teste-docker
  ```

---

## 🧹 Desinstalação Completa (Clean Uninstall)

Caso precise remover completamente o Docker, suas configurações, repositórios e todos os dados armazenados no servidor, execute o script `uninstall_docker.sh`.

> ⚠️ **AVISO CRÍTICO DE PERDA DE DADOS:** A execução abaixo é **irreversível** e apagará permanentemente todos os contêineres, imagens, redes personalizadas e **volumes de dados** (`/var/lib/docker`). Faça backup antes de prosseguir.

* **Usuário Comum (com privilégios `sudo`):**
  ```bash
  curl -fsSL https://githubusercontent.com | sudo bash
  ```

* **Usuário `root` (direto no terminal administrativo):**
  ```bash
  curl -fsSL https://githubusercontent.com | bash
  ```

### O que o script de desinstalação remove
1. **Serviços:** Para e desativa `docker.service`, `docker.socket` e `containerd.service`.
2. **Pacotes (`purge`):** Remove `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin` e dependências órfãs.
3. **Dados e Volumes:** Exclui permanentemente `/var/lib/docker`, `/var/lib/containerd` e `/var/run/docker.sock`.
4. **Configurações e Repositórios:** Apaga `/etc/docker`, `/etc/apt/sources.list.d/docker.sources` e `/etc/apt/keyrings/docker.asc`.
5. **Manutenção e Permissões:** Remove o agendamento `/etc/cron.d/docker-cleanup`, os logs de limpeza e o grupo `docker`.
