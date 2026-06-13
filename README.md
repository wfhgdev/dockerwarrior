# 🐳 DockerWarrior by William H.

<div align="center">

### **Your Self-Hosted Server Deployment Warrior**

*Transform a fresh Linux server into a complete Docker-powered self-hosted platform in minutes.*

![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-Debian%20%7C%20Ubuntu-blue)
![Docker](https://img.shields.io/badge/Docker-Engine-2496ED?logo=docker\&logoColor=white)
![Shell](https://img.shields.io/badge/Bash-Automation-black?logo=gnu-bash)

</div>

---

## ⚔️ What is DockerWarrior?

DockerWarrior is an automated installation assistant designed to transform a clean Debian or Ubuntu server into a complete, secure and easy-to-manage self-hosted platform.

With a single installation command, DockerWarrior prepares your server, installs the Docker ecosystem and helps you deploy popular self-hosted applications using Docker Compose stacks.

The project follows a modular architecture, allowing new applications to be added easily as independent modules.

---

## 🚀 Main Features

### 🐋 Docker Platform

* Automatic installation of Docker Engine
* Docker Compose Plugin installation
* Docker networking preparation
* Docker environment validation

### 🛠️ Management Tools

* Dockge installation for Docker Compose stack management
* Portainer installation for Docker container administration

### 📦 Self-Hosted Applications

Supported and planned applications:

| Category         | Applications                  |
| ---------------- | ----------------------------- |
| Reverse Proxy    | Nginx Proxy Manager           |
| VPN              | WG-Easy                       |
| Cloud            | Nextcloud                     |
| Media            | Jellyfin                      |
| Photos           | Immich                        |
| DNS & Network    | AdGuard Home                  |
| Business         | Odoo Community Edition        |
| Password Manager | Vaultwarden                   |
| Surveys          | LimeSurvey                    |
| Security         | Fail2Ban (crazy-max/fail2ban) |
| Mail             | Docker Mail Server            |

---

## 🧱 Architecture Philosophy

DockerWarrior does not simply execute Docker commands.

It creates a structured self-hosted environment:

```text
Fresh Debian / Ubuntu Server
              |
              v
      DockerWarrior Installer
              |
              v
      Docker Engine + Compose
              |
              v
        Dockge + Portainer
              |
              v
        Docker Compose Stacks
              |
              v
      Your Self-Hosted Services
```

All applications are deployed as independent Docker stacks:

```text
/opt/stacks/

├── nginx-proxy-manager/
├── nextcloud/
├── vaultwarden/
├── jellyfin/
├── immich/
└── adguard-home/
```

---

## 💻 Installation

Coming soon.

The final installation will be as simple as:

```bash
wget https://raw.githubusercontent.com/wfhgdev/dockerwarrior/main/install.sh -O install.sh && bash install.sh
```

---

## 🌐 Multi-language Support

DockerWarrior is designed from the beginning with internationalization support.

Initial languages:

* 🇺🇸 English
* 🇪🇸 Spanish

All user interface texts are stored in independent language files.

---

## 🛡️ Security Features (Planned)

Optional security modules:

* System updates
* UFW Firewall configuration
* SSH hardening
* Automatic security updates
* Docker Fail2Ban integration

---

## 📋 Project Roadmap

### Version 0.1 - Core Platform

* [ ] Debian and Ubuntu detection
* [ ] System validation
* [ ] Logging system
* [ ] Internationalization
* [ ] Interactive menus
* [ ] Docker installation
* [ ] Docker Compose installation

### Version 0.5 - Docker Management

* [ ] Dockge installation
* [ ] Portainer installation
* [ ] Docker stack template system

### Version 1.0 - Essential Applications

* [ ] Nginx Proxy Manager
* [ ] WG-Easy
* [ ] Vaultwarden
* [ ] AdGuard Home
* [ ] Jellyfin
* [ ] Immich
* [ ] Nextcloud

### Future Versions

* [ ] Odoo Community
* [ ] LimeSurvey
* [ ] Mail Server
* [ ] Backup & Restore
* [ ] Automatic updates
* [ ] Additional Docker applications

---

## 📂 Planned Repository Structure

```text
dockerwarrior/

├── install.sh
├── lib/
├── apps/
├── templates/
├── config/
├── lang/
└── docs/
```

---

## 🤝 Contributing

Contributions, ideas and suggestions are welcome.

If you have a Docker application that would fit DockerWarrior, feel free to open an Issue or submit a Pull Request.

---

## ⭐ Support the Project

If DockerWarrior helps you build your self-hosted infrastructure, consider giving the repository a ⭐ on GitHub.

It helps the project grow and reach more self-hosting enthusiasts.

---

## 📜 License

This project will be released under the MIT License.

---

<div align="center">

### 🐳⚔️ DockerWarrior

**Build your own self-hosted kingdom, one container at a time.**

**Instalation**

Option 1: Download and run. This command downloads the file to your current directory and then runs it. It's the cleanest option if you want to keep the script for future local modifications.

```Shell
wget https://raw.githubusercontent.com/wfhgdev/dockerwarrior/main/scaffolding.sh -O scaffolding.sh && bash scaffolding.sh
```

Option 2: Direct in-memory execution. If you don't want to store the scaffolding.sh executable file on your machine and just want it to create the folder structure immediately, you can pipe it directly to bash using curl:

```Shell
curl -sSL https://raw.githubusercontent.com/wfhgdev/dockerwarrior/main/scaffolding.sh | bash
```
