# 🐳 Docker Ubuntu Setup

**Instalação automatizada e configuração segura do Docker Engine e Docker Compose em servidores Ubuntu.**

[![CI](https://github.com/wellingt0n-0liveira/docker-ubuntu-setup/actions/workflows/lint.yml/badge.svg?branch=main&style=flat-square)](https://github.com/wellingt0n-0liveira/docker-ubuntu-setup/actions/workflows/lint.yml)
[![Licença MIT](https://img.shields.io/badge/licen%C3%A7a-MIT-green.svg?style=flat-square)](LICENSE)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%2B-E95420?logo=ubuntu&logoColor=white&style=flat-square)](https://ubuntu.com/)
[![Docker Engine](https://img.shields.io/badge/Docker-Engine-2496ED?logo=docker&logoColor=white&style=flat-square)](https://docs.docker.com/engine/)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-validado-brightgreen?style=flat-square)](https://www.shellcheck.net/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](CONTRIBUTING.md)

</div>

> [!CAUTION]
> **Aviso de segurança:** revise o código dos scripts e entenda as alterações que serão feitas no sistema antes de executá-los, especialmente em servidores de produção. Os comandos de instalação alteram pacotes, repositórios, configurações do Docker, permissões e tarefas agendadas. Faça backup e teste primeiro em um ambiente controlado.

## 📑 Índice

- [Por que usar?](#-por-que-usar)
- [Visão geral](#-visão-geral)
- [Requisitos](#-requisitos)
- [Instalação rápida](#-instalação-rápida)
- [O que o script configura](#️-o-que-o-script-configura)
- [Log de exemplo](#-log-de-exemplo)
- [Teste automatizado do ambiente](#-teste-automatizado-do-ambiente-low-resource--raspberry-pi)
- [Limpar o ambiente de teste](#-limpar-o-ambiente-de-teste)
- [Desinstalação completa](#-desinstalação-completa-clean-uninstall)
- [CI/CD](#-cicd)
- [Contribuindo](#-contribuindo)
- [Licença](#-licença)

## 💡 Por que usar?

- **Instalação automatizada e idempotente:** execute o script novamente sem refazer manualmente toda a configuração.
- **Repositório oficial do Docker:** instala os pacotes oficiais do Docker Engine e do Docker Compose.
- **Configuração com foco em produção:** aplica limites de logs, isolamento de rede e opções de segurança do daemon.
- **Manutenção programada:** configura limpeza semanal de imagens e caches órfãos, preservando volumes.
- **Validação incluída:** verifica versões, configurações e execução de um contêiner de teste.

## 🧭 Visão geral

O projeto automatiza a instalação e configuração do **Docker Engine** e do **Docker Compose** em servidores Ubuntu. O script também aplica configurações de segurança, rede e manutenção, e valida a instalação ao final.

## 📋 Requisitos

| Requisito           | Detalhes                                                     |
| ------------------- | ------------------------------------------------------------ |
| Sistema operacional | Ubuntu 20.04 LTS, 22.04 LTS, 24.04 LTS ou superior           |
| Arquiteturas        | `amd64`, `arm64` e `armhf` — a disponibilidade dos pacotes pode variar conforme a versão do Ubuntu e o repositório oficial do Docker |
| Acesso              | Conexão com a internet e privilégios de `sudo` ou acesso como `root` |
| Utilitário          | `curl` instalado                                             |

> **Nota sobre ARM:** confirme que a versão do Ubuntu e a arquitetura da máquina são suportadas pelo repositório de pacotes do Docker antes de executar a instalação.

## 🚀 Instalação rápida

Os comandos abaixo baixam e executam o script de instalação diretamente. Para ambientes de produção, considere baixar o arquivo, revisar seu conteúdo e só então executá-lo.

### Usuário comum com `sudo`

```bash
curl -fsSL \
  https://raw.githubusercontent.com/wellingt0n-0liveira/docker-ubuntu-setup/refs/heads/main/install_docker.sh \
  | sudo bash
```

Se o usuário precisar de senha para executar comandos `sudo`, ela será solicitada pelo sistema.

### Usuário `root`

```bash
curl -fsSL \
  https://raw.githubusercontent.com/wellingt0n-0liveira/docker-ubuntu-setup/refs/heads/main/install_docker.sh \
  | bash
```

## ⚙️ O que o script configura

1. **Limpeza de conflitos:** remove versões antigas ou não oficiais, como `docker.io`, `podman-docker` e `containerd`, além de limpar repositórios legados.
2. **Repositório oficial moderno:** configura a chave GPG `.asc` e o repositório do Docker no formato DEB822 em `/etc/apt/sources.list.d/docker.sources`.
3. **Pacotes instalados:** `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin` e `docker-compose-plugin`.
4. **Hardening e configuração de produção** em `/etc/docker/daemon.json`:
   - **Rotação de logs:** limita cada arquivo de log a `10MB`, com retenção de até 3 arquivos por contêiner.
   - **Isolamento de rede:** define o pool interno `172.28.0.0/16`, dividido em sub-redes `/24`, para ajudar a evitar conflitos com redes locais e VPNs.
   - **Segurança e disponibilidade:** ativa `live-restore: true` e `no-new-privileges: true`, além de desativar o `userland-proxy`.
5. **Manutenção automática:** agenda em `/etc/cron.d/docker-cleanup` uma limpeza semanal, aos domingos às 03:00, de imagens e caches órfãos com mais de 7 dias (`168h`). Os volumes de dados são preservados por essa rotina.
6. **Permissões pós-instalação:** adiciona o usuário atual ao grupo `docker`, permitindo executar comandos Docker sem `sudo` após atualizar a sessão. **Atenção:** pertencer ao grupo `docker` concede privilégios elevados, equivalentes na prática a acesso administrativo ao sistema.
7. **Validação automática:** verifica versões, driver de log, criação de sub-rede e execução de um contêiner temporário `hello-world`.

## 🧾 Log de exemplo

A saída exata pode variar conforme a versão do sistema e dos pacotes. O exemplo abaixo representa o tipo de resumo esperado ao final de uma instalação bem-sucedida; não é uma transcrição garantida do script:

```text
[OK] Docker Engine instalado
[OK] Docker Compose disponível
[OK] Configuração do daemon validada
[OK] Pool de rede 172.28.0.0/16 configurado
[OK] Contêiner hello-world executado com sucesso

Docker version: 27.x.x
Docker Compose version: v2.x.x
Status: instalação e validação concluídas
```

## 🧪 Teste automatizado do ambiente (Low-Resource / Raspberry Pi)

Este teste valida o Docker Compose, o isolamento de rede (`172.28.0.0/16`) e os limites de recursos. O contêiner de teste usa `busybox:1.36-musl` (imagem inferior a 2 MB), sistema de arquivos somente leitura (`read_only: true`), sem capacidades adicionais (`cap_drop: ALL`) e limite de **32 MB de RAM**.

### Usuário comum

O comando usa `sg docker` para executar as operações com o grupo Docker sem exigir que você encerre e inicie uma nova sessão:

```bash
mkdir -p ~/teste-docker \
  && cd ~/teste-docker \
  && curl -fsSLO \
    https://raw.githubusercontent.com/wellingt0n-0liveira/docker-ubuntu-setup/refs/heads/main/docker-compose.yml \
  && sg docker -c \
    "docker compose up -d \
      && sleep 3 \
      && docker ps --filter 'name=app-web-teste'
```

### Usuário `root`

```bash
mkdir -p ~/teste-docker \
  && cd ~/teste-docker \
  && curl -fsSLO \
    https://raw.githubusercontent.com/wellingt0n-0liveira/docker-ubuntu-setup/refs/heads/main/docker-compose.yml \
  && docker compose up -d \
  && sleep 3 \
  && docker ps --filter 'name=app-web-teste'
```

## 🧹 Limpar o ambiente de teste

Os comandos abaixo removem o contêiner e a rede do Compose e excluem a pasta temporária `~/teste-docker`. Confira o caminho antes de executá-los.

### Usuário comum

```bash
cd ~/teste-docker \
  && sg docker -c "docker compose down" \
  && cd ~ \
  && rm -rf ~/teste-docker
```

### Usuário `root`

```bash
cd ~/teste-docker \
  && docker compose down \
  && cd ~ \
  && rm -rf ~/teste-docker
```

## 🗑️ Desinstalação completa (Clean Uninstall)

Use `uninstall_docker.sh` para remover o Docker, suas configurações, repositórios e dados armazenados no servidor.

> [!WARNING]
> **Perda irreversível de dados:** a desinstalação remove permanentemente contêineres, imagens, redes personalizadas e volumes de dados, incluindo `/var/lib/docker`. Faça e verifique um backup antes de continuar. Não execute em produção sem avaliar o impacto e confirmar que os dados podem ser descartados.

### Usuário comum com `sudo`

```bash
curl -fsSL \
  https://raw.githubusercontent.com/wellingt0n-0liveira/docker-ubuntu-setup/refs/heads/main/uninstall_docker.sh \
  | sudo bash
```

### Usuário `root`

```bash
curl -fsSL \
  https://raw.githubusercontent.com/wellingt0n-0liveira/docker-ubuntu-setup/refs/heads/main/uninstall_docker.sh \
  | bash
```

### O que o script de desinstalação remove

1. **Serviços:** para e desativa `docker.service`, `docker.socket` e `containerd.service`.
2. **Pacotes:** remove `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin` e dependências órfãs.
3. **Dados e volumes:** exclui `/var/lib/docker`, `/var/lib/containerd` e `/var/run/docker.sock`.
4. **Configurações e repositórios:** apaga `/etc/docker`, `/etc/apt/sources.list.d/docker.sources` e `/etc/apt/keyrings/docker.asc`.
5. **Manutenção e permissões:** remove `/etc/cron.d/docker-cleanup`, os logs de limpeza e o grupo `docker`.

## 🔄 CI/CD

O repositório usa GitHub Actions (.github/workflows/lint.yml) para executar verificações automatizadas. O workflow utiliza:

•ShellCheck: análise estática dos scripts shell para identificar erros comuns e problemas de portabilidade.

•Docker Compose config: executa docker compose -f docker-compose.yml config --quiet para verificar se a configuração do Compose pode ser carregada corretamente. Esse comando não é um YAML Lint genérico; ele valida o arquivo conforme as regras do Docker Compose.

Consulte .github/workflows/lint.yml para confirmar os eventos que acionam as verificações e os comandos configurados atualmente.



## 🤝 Contribuindo

Contribuições são bem-vindas. Para propor uma alteração:

1. Abra uma issue para relatar um problema ou discutir uma melhoria relevante.
2. Faça um fork do repositório e crie uma branch descritiva a partir de `main`.
3. Implemente a alteração e valide os scripts com ShellCheck e os arquivos YAML com YAML Lint.
4. Abra um pull request explicando o problema, a solução e como a alteração foi testada.
5. Sempre que possível, mantenha as alterações pequenas e atualize a documentação relacionada.

Ao abrir uma issue, inclua a versão do Ubuntu, a arquitetura, os passos para reproduzir o problema e mensagens de erro relevantes. Não publique segredos, tokens ou dados sensíveis.

## 📄 Licença

Este projeto está licenciado sob a **Licença MIT**. Consulte o arquivo [`LICENSE`](LICENSE) para ver o texto completo.

<div align="center">


Feito com foco em automação, segurança e simplicidade para Ubuntu.

</div>
