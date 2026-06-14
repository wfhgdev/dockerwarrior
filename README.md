# ⚔️ DockerWarrior

<p align="center">
  <strong>The Ultimate Self-Hosting Docker Deployment Framework</strong>
</p>

<p align="center">
  Deploy your private cloud infrastructure in minutes with a secure, modular and production-ready Docker automation framework.
</p>

---

## 🚀 What is DockerWarrior?

DockerWarrior is an automated installation and deployment framework designed to transform a fresh Linux server into a complete self-hosting platform.

Unlike traditional installation scripts, DockerWarrior follows a **declarative architecture** where applications are packaged as independent modules and deployed through a generic infrastructure engine.

The project installs and configures the complete Docker ecosystem:

- 🐳 Docker Engine
- 🧩 Docker Compose Plugin
- 📦 Dockge Stack Manager
- 🎛️ Portainer CE

Once the foundation is ready, DockerWarrior allows the administrator to deploy additional services through an interactive terminal interface.

---

# ✨ Core Principles

DockerWarrior has been designed following enterprise infrastructure principles:

### 🔹 Modular Architecture

Each application is a self-contained package inside:

```

templates/<app_id>/

```

Adding new applications does not require modifications to the core engine.

---

### 🔹 Declarative Deployment Engine

The deployment workflow is handled by a generic engine:

```

lib/core/engine.sh

```

The engine is responsible for:

- Creating production stacks under `/opt/stacks`
- Processing Docker Compose templates
- Generating secure secrets dynamically
- Managing application lifecycle hooks
- Maintaining a predictable deployment pipeline

---

### 🔹 Security by Default

DockerWarrior follows the **DW-AppSpec v1.1** security standard.

Features include:

- Automatic generation of random secrets
- `.env` files protected with `chmod 600`
- No passwords stored in Git repositories
- Network isolation between application and database layers
- Least-privilege communication model
- Shared reverse-proxy network architecture

Example:

```

Internet
|
Nginx Proxy Manager
|
dw_proxy_network
|
Application Container
|
Private Stack Network
|
Database Container

```

Database services are never exposed to the global proxy network.

---

### 🔹 Production Stack Structure

All generated stacks are stored under:

```

/opt/stacks/

```

Example:

```

/opt/stacks/
└── nginx_proxy_manager/
├── compose.yaml
├── .env
├── data/
└── mysql/

```

This makes DockerWarrior fully compatible with Dockge and Portainer management interfaces.

---

### 🔹 Internationalized Terminal Interface

DockerWarrior includes a dynamic language system:

```

lang/
├── en.sh
└── es.sh

```

The installer automatically loads the selected language and renders all menus and messages dynamically.

---

## 📦 Available Applications

Current production-ready catalog:

| Category | Application | Status |
|---|---|---|
| Reverse Proxy | Nginx Proxy Manager | ✅ Supported |

Planned applications:

- Vaultwarden
- Nextcloud
- Immich
- Jellyfin
- WG-Easy
- AdGuard Home
- Odoo Community Edition
- LimeSurvey
- Mail Server Stack
- Fail2Ban

---

## ⚡ One-Line Installation

Deploy DockerWarrior with a single command:

```bash
git clone https://github.com/wfhgdev/dockerwarrior.git && cd dockerwarrior && chmod +x install.sh && sudo ./install.sh
```

---

## 📋 Installation Workflow

DockerWarrior performs the following operations:

1. Validates operating system and architecture.
2. Checks interactive terminal compatibility.
3. Installs required dependencies.
4. Installs Docker Engine and Docker Compose.
5. Creates shared infrastructure resources.
6. Deploys Dockge.
7. Deploys Portainer CE.
8. Displays the application catalog.
9. Generates secure production-ready stacks.

---

## 🏗️ Project Structure

```

dockerwarrior/
│
├── install.sh
│
├── apps/
│ └── core/
│ ├── dockge.sh
│ └── portainer.sh
│
├── config/
│ └── apps.conf
│
├── docs/
│ └── DW-AppSpec-v1.1.md
│
├── lang/
│ ├── en.sh
│ └── es.sh
│
├── lib/
│ ├── core/
│ │ ├── engine.sh
│ │ ├── logger.sh
│ │ ├── system.sh
│ │ └── utils.sh
│ │
│ └── ui/ 
│ ├── dialogs.sh
│ └── menu.sh
│ 
└── templates/
└── nginx_proxy_manager/
├── metadata.conf
├── compose.yaml
└── env.template

---

## 🧾 DockerWarrior Application Specification

All applications must comply with the official standard:

**DW-AppSpec v1.1**

The specification defines:

- Application package topology
- Metadata contract
- Compose security rules
- Environment variable management
- Secret generation system
- Network isolation model
- Pre/Post deployment hooks

See:

```
docs/DW-AppSpec-v1.1.md
```

---

## 🛡️ Security Philosophy

DockerWarrior is designed around the concept:

> The safest service is the one that only has access to what it strictly needs.

Each stack uses layered networking:

- Frontend containers can access the shared reverse-proxy network.
- Databases and internal services remain isolated inside the private Docker network.
- Secrets are generated only at deployment time.

---

## 🗺️ Roadmap

### DockerWarrior Core v1.0
- [x] Docker installation engine
- [x] Docker Compose integration
- [x] Dockge deployment
- [x] Portainer deployment
- [x] Generic deployment engine
- [x] Template processing system
- [x] Secret generation engine
- [x] Internationalization
- [x] DW-AppSpec v1.1 compliance

### Phase 7 - Application Catalog Expansion
- [ ] Vaultwarden
- [ ] Nextcloud
- [ ] Immich
- [ ] Jellyfin
- [ ] WG-Easy
- [ ] AdGuard Home
- [ ] Odoo Community Edition
- [ ] LimeSurvey
- [ ] Mail Server Stack

---

## 🤝 Contributing

Contributions are welcome.

To add a new application, developers only need to create a new package inside:

```

templates/<new_application>/

```

The DockerWarrior core will automatically process it without modifying the main installer.

---

## 📄 License

This project is distributed under the MIT License.

---

<p align="center">
⚔️ DockerWarrior — Build your private cloud. Securely. Elegantly. Automatically.
</p>