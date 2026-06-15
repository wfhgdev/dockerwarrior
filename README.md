# ⚔️ DockerWarrior by William H.

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

* 🐳 Docker Engine
* 🧩 Docker Compose Plugin
* 📦 Dockge Stack Manager
* 🎛️ Portainer CE
* 🖥️ Interactive Whiptail Application Selector

Once the foundation is ready, DockerWarrior presents an interactive application catalog where administrators can select additional services to prepare automatically.

---

# ✨ Core Principles

DockerWarrior has been designed following enterprise infrastructure principles.

---

## 🔹 Modular Architecture

Each application is a self-contained package inside:

```text
templates/<app_id>/
```

Adding new applications does not require modifications to the core engine.

---

## 🔹 Declarative Deployment Engine

The deployment workflow is handled by:

```text
lib/core/engine.sh
```

The engine is responsible for:

* Creating production stacks under `/opt/stacks`
* Processing Docker Compose templates
* Generating secure secrets dynamically
* Managing application lifecycle hooks
* Maintaining a predictable deployment pipeline

---

## 🔹 Security by Default

DockerWarrior follows the **DW-AppSpec v1.1** security standard.

Security features include:

* Automatic generation of random secrets
* `.env` files protected with `chmod 600`
* No passwords stored inside Git repositories
* Network isolation between application and database layers
* Least-privilege communication model
* Shared reverse-proxy network architecture

Architecture example:

```text
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

## 🔹 Production Stack Structure

All generated stacks are stored under:

```text
/opt/stacks/
```

Example:

```text
/opt/stacks/
└── nginx_proxy_manager/
    ├── compose.yaml
    ├── .env
    ├── data/
    └── mysql/
```

This structure provides native compatibility with Dockge and Portainer.

---

## 🔹 Internationalized Terminal Interface

DockerWarrior includes a dynamic language system:

```text
lang/
├── en.sh
└── es.sh
```

The installer automatically loads the selected language and renders messages dynamically.

---

## 🔹 Interactive Application Catalog

DockerWarrior includes a dynamic terminal interface based on Whiptail.

The available application catalog is defined declaratively in:

```text
config/apps.conf
```

Example:

```text
nginx_proxy_manager|Nginx Proxy Manager|network
vaultwarden|Vaultwarden|security
nextcloud|Nextcloud Hub|cloud
```

The selection workflow includes:

* Interactive multi-selection menu
* Dynamic catalog loading
* Input sanitization and application ID validation
* Safe communication between UI and Core layers
* Graceful handling of user cancellation
* Automatic validation of application templates

New applications can be added without modifying the installer logic.

---

# 📦 Available Applications

Current catalog:

| Category | Application         | Status      |
| -------- | ------------------- | ----------- |
| Network  | Nginx Proxy Manager | ✅ Supported |
| Security | Vaultwarden         | 🚧 Planned  |
| Cloud    | Nextcloud Hub       | 🚧 Planned  |
| Network  | WireGuard Easy      | 🚧 Planned  |
| Network  | AdGuard Home        | 🚧 Planned  |
| Media    | Jellyfin            | 🚧 Planned  |
| Media    | Immich Photos       | 🚧 Planned  |
| Mail     | Docker Mailserver   | 🚧 Planned  |

---

# ⚡ One-Line Installation

Deploy DockerWarrior using a single command:

```bash
git clone https://github.com/wfhgdev/dockerwarrior.git && cd dockerwarrior && chmod +x install.sh && sudo ./install.sh
```

---

# 📋 Installation Workflow

DockerWarrior performs the following operations:

1. Validates root privileges and system compatibility.
2. Loads the selected language pack.
3. Installs required system dependencies (Whiptail, Curl, OpenSSL, GnuPG).
4. Installs or validates Docker Engine.
5. Verifies Docker Compose availability.
6. Creates the shared `dw_proxy_network`.
7. Deploys Dockge Stack Manager.
8. Deploys Portainer CE.
9. Displays the interactive application catalog.
10. Validates selected applications.
11. Generates secure production-ready Docker stacks.
12. Generates a complete deployment report.

---

# 🏗️ Project Structure

```text
dockerwarrior/
│
├── install.sh
│
├── apps/
│   └── core/
│       ├── dockge.sh
│       └── portainer.sh
│
├── config/
│   └── apps.conf
│
├── docs/
│   └── DW-AppSpec-v1.1.md
│
├── lang/
│   ├── en.sh
│   └── es.sh
│
├── lib/
│   ├── core/
│   │   ├── engine.sh
│   │   ├── logger.sh
│   │   ├── report.sh
│   │   ├── system.sh
│   │   └── utils.sh
│   │
│   └── ui/
│       ├── dialogs.sh
│       └── menu.sh
│
└── templates/
    └── nginx_proxy_manager/
        ├── metadata.conf
        ├── compose.yaml
        └── env.template
```

---

# 🧾 DockerWarrior Application Specification

All applications must comply with the official standard:

**DW-AppSpec v1.1**

The specification defines:

* Application package topology
* Metadata contract
* Docker Compose security rules
* Environment variable management
* Secret generation system
* Network isolation model
* Pre/Post deployment hooks

Documentation:

```text
docs/DW-AppSpec-v1.1.md
```

---

# 🛡️ Security Philosophy

DockerWarrior follows a simple principle:

> The safest service is the one that only has access to what it strictly needs.

Each application stack follows a layered network model:

* Frontend containers can communicate with the shared reverse-proxy network.
* Databases and internal services remain isolated inside their private Docker networks.
* Secrets are generated only at deployment time.
* No sensitive data is stored inside the Git repository.

---

# 🗺️ Roadmap

## DockerWarrior Core v1.0.x

### Completed Features

* [x] Docker Engine installation engine
* [x] Docker Compose integration
* [x] Dockge deployment
* [x] Portainer CE deployment
* [x] Generic declarative deployment engine
* [x] Template processing system
* [x] Secure secret generation
* [x] Internationalization (English / Spanish)
* [x] Interactive Whiptail application catalog
* [x] Dynamic application loading from `apps.conf`
* [x] UI/Core input sanitization
* [x] Deployment reporting system
* [x] DW-AppSpec v1.1 compliance

---

## Application Catalog Expansion

Planned applications:

* [ ] Vaultwarden
* [ ] Nextcloud Hub
* [ ] Immich Photos
* [ ] Jellyfin Media Server
* [ ] WireGuard Easy
* [ ] AdGuard Home
* [ ] Docker Mailserver
* [ ] Odoo Community Edition
* [ ] LimeSurvey
* [ ] Fail2Ban integration

---

# 🤝 Contributing

Contributions are welcome.

Adding a new application is simple:

1. Create a new package inside:

```text
templates/<new_application>/
```

2. Register the application inside:

```text
config/apps.conf
```

The DockerWarrior core will automatically discover the new application through the catalog system.

No modifications to `install.sh` or the deployment engine are required.

---

# 📄 License

This project is distributed under the MIT License.

---

<p align="center">
⚔️ DockerWarrior — Build your private cloud. Securely. Elegantly. Automatically.
</p>
