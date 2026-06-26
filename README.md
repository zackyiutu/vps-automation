<p align="center">
  <img src="https://abfool.web.id/banner.png" alt="abfool VPS Orchestration" width="100%">
</p>

# abfool VPS Orchestration

<p align="center">
  <a href="https://abfool.web.id"><img src="https://img.shields.io/badge/Website-abfool.web.id-00d4ff?style=for-the-badge" alt="Website"></a>
  <a href="https://abfool.web.id/docs"><img src="https://img.shields.io/badge/Docs-docs.abfool.web.id-FFD700?style=for-the-badge" alt="Documentation"></a>
  <a href="https://github.com/zackyiutu/vps-automation/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License: MIT"></a>
  <a href="https://github.com/zackyiutu/vps-automation/stargazers"><img src="https://img.shields.io/github/stars/zackyiutu/vps-automation?style=for-the-badge" alt="Stars"></a>
</p>

**Open-source autonomous VPS provisioning, orchestration & management system.** Zero-cost cloud infrastructure from 15+ free providers. Auto-creates accounts, provisions VPS, stores credentials, monitors health, and self-heals — all from your phone (Termux) or PC.

> **No credit card required.** The system handles everything: account creation, VPS provisioning, SSH key management, credential storage, and 24/7 monitoring.

---

## Features

| Feature | Description |
|---------|-------------|
| 🚀 **Auto-Provisioning** | One command → VPS ready with SSH, IP, credentials stored |
| 🤖 **LLM-Powered Workers** | Intelligent provisioning with AI decision-making |
| 📊 **Live Dashboard** | Real-time monitoring, charts, health status |
| 🔄 **Auto-Heal** | Restart dead instances, remount storage, self-recover |
| ☁️ **15+ Free Providers** | No CC: Fly.io, Gitpod, Codespaces, HuggingFace, Railway, Render, Koyeb, Deno, Vercel, Netlify, IBM, Northflank, Cyclic, CF Workers |
| 💾 **5TB Cloud Storage** | Google Drive mount via Rclone |
| 🌐 **Tunnels** | Cloudflare, Tailscale, SSH reverse, localhost.run |
| 📱 **Termux Native** | Full Android support, manage VPS from phone |
| 🔐 **Credential Vault** | Encrypted storage for all provider credentials |
| 🔔 **Notifications** | Telegram, Discord, Email, Webhook |

---

## Quick Start

```bash
# Clone & install
git clone https://github.com/zackyiutu/vps-automation.git
cd vps-automation
bash scripts/install.sh

# Setup (interactive wizard)
abfool-vps setup

# Create your first VPS (auto-provisioned)
abfool-vps create flyio my-server

# List all instances
abfool-vps list all

# SSH to instance
abfool-vps ssh flyio my-server
```

---

## Supported Providers

| Provider | Specs | CC Required | Auto-Account | Status |
|----------|-------|-------------|-------------|--------|
| [Fly.io](https://fly.io) | 3× VM, 256MB RAM | ❌ No | ✅ Yes | 🟢 |
| [Gitpod](https://gitpod.io) | 4 cores, 8GB RAM | ❌ No | ✅ Yes | 🟢 |
| [GitHub Codespaces](https://github.com/features/codespaces) | 2 cores, 8GB RAM | ❌ No | ✅ Yes | 🟢 |
| [HuggingFace Spaces](https://huggingface.co) | 2 vCPU, 16GB RAM | ❌ No | ✅ Yes | 🟢 |
| [Railway](https://railway.app) | 512MB RAM, 1GB disk | ❌ No | ✅ Yes | 🟢 |
| [Render](https://render.com) | 512MB RAM | ❌ No | ✅ Yes | 🟢 |
| [Koyeb](https://koyeb.com) | 2× nano, 512MB | ❌ No | ✅ Yes | 🟢 |
| [Deno Deploy](https://deno.com/deploy) | Serverless | ❌ No | ✅ Yes | 🟢 |
| [Vercel](https://vercel.com) | Serverless, 100GB BW | ❌ No | ✅ Yes | 🟢 |
| [Netlify](https://netlify.com) | 100GB BW, serverless | ❌ No | ✅ Yes | 🟢 |
| [IBM Cloud](https://cloud.ibm.com) | Lite tier, 256MB | ❌ No | ✅ Yes | 🟢 |
| [Northflank](https://northflank.com) | 2GB RAM, 2 vCPU | ❌ No | ✅ Yes | 🟢 |
| [Cyclic](https://cyclic.sh) | Serverless, 512MB | ❌ No | ✅ Yes | 🟢 |
| [Cloudflare Workers](https://workers.cloudflare.com) | 10ms CPU, 128MB | ❌ No | ✅ Yes | 🟢 |
| [Cloudflare Pages](https://pages.cloudflare.com) | Unlimited BW | ❌ No | ✅ Yes | 🟢 |

---

## Powered By

This project integrates **40+ open-source tools** from the community:

### Core Infrastructure
| Tool | Purpose | Repo |
|------|---------|------|
| [Terraform](https://github.com/hashicorp/terraform) | Infrastructure as Code | `hashicorp/terraform` |
| [Pulumi](https://github.com/pulumi/pulumi) | IaC with real programming languages | `pulumi/pulumi` |
| [Ansible](https://github.com/ansible/ansible) | Configuration management | `ansible/ansible` |

### Cloud & Provisioning
| Tool | Purpose | Repo |
|------|---------|------|
| [OCI CLI](https://github.com/oracle/oci-cli) | Oracle Cloud CLI | `oracle/oci-cli` |
| [Flyctl](https://github.com/superfly/flyctl) | Fly.io CLI | `superfly/flyctl` |
| [GitHub CLI](https://github.com/cli/cli) | GitHub Codespaces | `cli/cli` |
| [Vercel CLI](https://github.com/vercel/vercel) | Vercel deployments | `vercel/vercel` |
| [Netlify CLI](https://github.com/netlify/cli) | Netlify deployments | `netlify/cli` |
| [Wrangler](https://github.com/cloudflare/workers-sdk) | Cloudflare Workers/Pages | `cloudflare/workers-sdk` |
| [Railway CLI](https://github.com/railwayapp/cli) | Railway deployments | `railwayapp/cli` |
| [Koyeb CLI](https://github.com/koyeb/koyeb-cli) | Koyeb deployments | `koyeb/koyeb-cli` |
| [Deno](https://github.com/denoland/deno) | Deno Deploy runtime | `denoland/deno` |

### Storage & Data
| Tool | Purpose | Repo |
|------|---------|------|
| [Rclone](https://github.com/rclone/rclone) | Cloud storage sync | `rclone/rclone` |
| [SQLite](https://github.com/nicoritschel/sqlite) | Local credential DB | `nicoritschel/sqlite` |
| [Litestream](https://github.com/benbjohnson/litestream) | SQLite replication | `benbjohnson/litestream` |
| [MinIO](https://github.com/minio/minio) | S3-compatible storage | `minio/minio` |

### Networking & Tunnels
| Tool | Purpose | Repo |
|------|---------|------|
| [Cloudflared](https://github.com/cloudflare/cloudflared) | Cloudflare Tunnel | `cloudflare/cloudflared` |
| [Tailscale](https://github.com/tailscale/tailscale) | WireGuard mesh VPN | `tailscale/tailscale` |
| [ngrok](https://github.com/inconshreveable/ngrok) | Local tunnel | `inconshreveable/ngrok` |
| [localhost.run](https://localhost.run) | SSH tunnel (no install) | `localhost-run` |
| [bore](https://github.com/ekzhang/bore) | Simple TCP tunnel | `ekzhang/bore` |
| [Traefik](https://github.com/traefik/traefik) | Reverse proxy | `traefik/traefik` |
| [Caddy](https://github.com/caddyserver/caddy) | Web server + reverse proxy | `caddyserver/caddy` |

### Monitoring & Observability
| Tool | Purpose | Repo |
|------|---------|------|
| [Uptime Kuma](https://github.com/louislam/uptime-kuma) | Uptime monitoring | `louislam/uptime-kuma` |
| [Grafana](https://github.com/grafana/grafana) | Dashboards | `grafana/grafana` |
| [Prometheus](https://github.com/prometheus/prometheus) | Metrics | `prometheus/prometheus` |

### LLM & AI
| Tool | Purpose | Repo |
|------|---------|------|
| [LangChain](https://github.com/langchain-ai/langchain) | LLM orchestration | `langchain-ai/langchain` |
| [OpenAI Python](https://github.com/openai/openai-python) | OpenAI API client | `openai/openai-python` |
| [LiteLLM](https://github.com/BerriAI/litellm) | Multi-provider LLM proxy | `BerriAI/litellm` |
| [Ollama](https://github.com/ollama/ollama) | Local LLM inference | `ollama/ollama` |

### Automation & Workflow
| Tool | Purpose | Repo |
|------|---------|------|
| [n8n](https://github.com/n8n-io/n8n) | Workflow automation | `n8n-io/n8n` |
| [Temporal](https://github.com/temporalio/temporal) | Durable execution | `temporalio/temporal` |
| [Headless Chrome](https://github.com/puppeteer/puppeteer) | Browser automation | `puppeteer/puppeteer` |
| [Playwright](https://github.com/microsoft/playwright) | Cross-browser testing | `microsoft/playwright` |

### Security & Auth
| Tool | Purpose | Repo |
|------|---------|------|
| [age](https://github.com/FiloSottile/age) | File encryption | `FiloSottile/age` |
| [SOPS](https://github.com/getsops/sops) | Secrets management | `getsops/sops` |
| [Vault](https://github.com/hashicorp/vault) | Secrets management | `hashicorp/vault` |

### Databases
| Tool | Purpose | Repo |
|------|---------|------|
| [Redis](https://github.com/redis/redis) | In-memory cache | `redis/redis` |
| [PostgreSQL](https://github.com/postgres/postgres) | Relational DB | `postgres/postgres` |
| [MongoDB](https://github.com/mongodb/mongo) | Document DB | `mongodb/mongo` |
| [Dgraph](https://github.com/dgraph-io/dgraph) | Graph database | `dgraph-io/dgraph` |
| [Neo4j](https://github.com/neo4j/neo4j) | Graph database | `neo4j/neo4j` |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    abfool VPS Orchestration                  │
├─────────────────────────────────────────────────────────────┤
│  CLI (abfool-vps)  │  TUI Dashboard  │  Web Dashboard      │
├─────────────────────────────────────────────────────────────┤
│                    Core Engine                               │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │ Provider  │ │  Worker  │ │  LLM     │ │ Storage  │       │
│  │ Manager   │ │  Engine  │ │  Brain   │ │ Manager  │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
├─────────────────────────────────────────────────────────────┤
│  Providers                                                  │
│  Fly.io│Gitpod│Codespaces│HF│Railway│Render│Koyeb│Deno│... │
├─────────────────────────────────────────────────────────────┤
│  Infrastructure                                             │
│  Terraform│Ansible│Rclone│Tailscale│Cloudflare│SQLite       │
└─────────────────────────────────────────────────────────────┘
```

---

## License

[MIT](LICENSE) © [zackyiutu](https://github.com/zackyiutu)
