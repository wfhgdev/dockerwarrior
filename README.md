<div align="center">

# ⚔️ DockerWarrior by William H.

### The Self-Hosted Docker Deployment Framework

<img src="docs/images/dockerwarrior-banner.png" alt="DockerWarrior Banner">

**Build your private cloud with the power of Docker, the simplicity of a wizard, and the reliability of an enterprise-grade framework.**

[![Version](https://img.shields.io/badge/version-Core%20v1.0-blue.svg)]()
[![License](https://img.shields.io/badge/license-MIT-green.svg)]()
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED.svg)]()
[![Platform](https://img.shields.io/badge/platform-Ubuntu%20Server-orange.svg)]()

</div>

---

## 🚀 What is DockerWarrior?

DockerWarrior is not just another Docker installation script.

It is a **declarative self-hosted deployment framework** designed to transform a clean Linux server into a complete Docker ecosystem with a guided installation experience.

The DockerWarrior Core installs and configures:

- 🐳 Docker Engine
- 🧩 Docker Compose
- 📦 Dockge stack manager
- 🖥️ Portainer management interface
- 🌐 Reverse proxy infrastructure
- 🔐 Secure secrets management engine
- 🌍 Multi-language interactive interface

Once the core is installed, applications are deployed through independent packages that follow the **DW-AppSpec v1.0 standard**.

---

# 🏛️ DockerWarrior Architecture

```
                     DockerWarrior Core
                              |
      ------------------------------------------------
      |                      |                       |
 Infrastructure          Deployment Engine       User Interface
      |                      |                       |
 Docker               DW-AppSpec v1.0          Whiptail TUI
 Dockge               Templates                EN / ES
 Portainer            Secrets Engine
 Proxy Network        Environment Injection
                              |
                              |
                    Applications Catalog
                              |
    ---------------------------------------------------
    |         |          |          |         |        |
Vaultwarden Nextcloud Jellyfin Immich WG-Easy AdGuard
```

---

# ✨ Key Features

## 🧱 Stable Core Architecture

DockerWarrior Core v1.0 is designed to remain unchanged while the application ecosystem grows.

Adding a new service does not require modifying:

- `install.sh`
- `lib/core/engine.sh`
- Infrastructure modules

New applications are simply added as:

```

templates/<app_id>/
├── metadata.conf
├── compose.yaml
├── env.template
├── pre_install.sh (optional)
└── post_install.sh (optional)

```

---

## 🔐 Automatic Secret Generation

No default passwords.
No insecure credentials stored in Git.

DockerWarrior generates secure secrets during deployment:

```env
DATABASE_PASSWORD={{SECRET:32}}
JWT_SECRET={{SECRET:64}}
```

Generated `.env` files are automatically protected:

```bash
chmod 600 .env
```

---

## 🌐 Reverse Proxy Ready

Applications are designed to integrate through a shared Docker network:

```

dw_proxy_network

```

This allows services to be securely exposed through Nginx Proxy Manager without unnecessarily exposing ports to the host.

---

## 🧩 DW-AppSpec v1.0

Every application follows a strict contract:

- Metadata-driven deployment.
- Relative data persistence.
- Environment isolation.
- Secure secret injection.
- Optional lifecycle hooks.
- Zero changes to the core.

---

## 🌍 Multi-language Interface

DockerWarrior includes a modular internationalization system:

- 🇺🇸 English
- 🇪🇸 Español

New languages can be added simply by creating a new file inside:

```bash
lang/
```

---

## 🛡️ Reliability and Safety

Designed with production principles:

- ✔ Idempotent installation
- ✔ Fail-fast error handling
- ✔ Modular architecture
- ✔ Isolated application stacks
- ✔ No hardcoded credentials
- ✔ Clean separation between core and applications

---

# 📂 Project Structure

```text
dockerwarrior/
│
├── install.sh              # Main orchestrator
│
├── apps/
│   └── core/
│       ├── docker.sh
│       ├── dockge.sh
│       └── portainer.sh
│
├── lib/
│   ├── core/
│   │   └── engine.sh       # DW deployment engine
│   │
│   └── ui/
│       ├── dialogs.sh
│       └── menu.sh
│
├── config/
│   └── apps.conf           # Application catalog
│
├── lang/
│   ├── en.sh
│   └── es.sh
│
└── templates/
    └── <app_id>/
        ├── metadata.conf
        ├── compose.yaml
        └── env.template
```

---

# 📦 Current Application Catalog

| Category | Application | Status |
|----------|-------------|--------|
| Reverse Proxy | Nginx Proxy Manager | ✅ Available |
| Password Manager | Vaultwarden | 🚧 Phase 7 |
| Cloud | Nextcloud | Planned |
| Media | Jellyfin | Planned |
| Photos | Immich | Planned |
| VPN | WG-Easy | Planned |
| DNS | AdGuard Home | Planned |
| Business | Odoo Community | Planned |
| Surveys | LimeSurvey | Planned |
| Security | Fail2ban | Planned |
| Mail | Docker Mail Server | Planned |

---

# ⚡ Quick Installation:

```bash
git clone https://github.com/wfhgdev/dockerwarrior.git && cd dockerwarrior && chmod +x install.sh && sudo ./install.sh
```

---

# 🗺️ Roadmap

## ✅ Phase 6 — DockerWarrior Core v1.0

- Stable core architecture
- Deployment engine
- DW-AppSpec v1.0
- Internationalization
- Interactive UI
- Nginx Proxy Manager reference package

## 🚧 Phase 7 — Application Ecosystem

Next milestone:

- Vaultwarden package
- Expanded application catalog

---

# 🤝 Contributing

DockerWarrior was designed to be community friendly.

Want to add a new service?

You don't need to modify the core.

Create a new package following DW-AppSpec:

```

templates/my_app/

```

and let the deployment engine do the rest.

---

# 📄 License

MIT License

---

<div align="center">

**⚔️ DockerWarrior — Deploy your self-hosted kingdom, one container at a time. ⚔️**

</div>
