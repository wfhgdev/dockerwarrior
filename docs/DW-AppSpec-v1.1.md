# DockerWarrior Application Specification (DW-AppSpec) v1.1

## Document Status

- **Version:** 1.1
- **Status:** Stable
- **Compatibility:** DockerWarrior Core v1.0
- **Last Updated:** June 2026

---

# 1. Introduction

DW-AppSpec defines the official contract that every application must follow to be integrated into the DockerWarrior ecosystem.

Its main objective is to ensure that all services are:

- Declarative.
- Decoupled from the framework core.
- Secure by default.
- Fully compatible with Dockge.
- Portable across servers.
- Easy to maintain and upgrade.

Since DockerWarrior Core v1.0, no application is allowed to introduce deployment logic directly into the main installer.

Every service must exist as a self-contained package inside:

```plaintext
templates/<app_id>/
```

---

# 2. Standard Package Structure

Each application must follow the following directory structure:

```plaintext
templates/
└── <app_id>/
    ├── metadata.conf      # Required
    ├── compose.yaml       # Required
    ├── env.template       # Required
    ├── pre_install.sh     # Optional
    └── post_install.sh    # Optional
```

---

# 3. metadata.conf File

The `metadata.conf` file defines the package metadata and infrastructure requirements.

Example:

```bash
APP_ID="vaultwarden"
APP_NAME="Vaultwarden Password Manager"
VERSION="latest"

REQUIRED_NETWORKS=(
    "dw_proxy_network"
)
```

Rules:

- Must be Bash compatible.
- `APP_ID` must exactly match the package directory name.
- `APP_NAME` must be a human-readable application name.
- `VERSION` should represent the main Docker image version.
- `REQUIRED_NETWORKS` defines required global Docker networks.

---

# 4. compose.yaml Rules

The `compose.yaml` file is the source of truth for container orchestration.

## 4.1 Mandatory env_file Usage

All services must delegate their environment configuration to a `.env` file.

Correct:

```yaml
env_file:
  - .env
```

Sensitive information must never be hardcoded directly inside `compose.yaml`.

---

## 4.2 Self-contained Persistence

All persistent volumes must use relative paths.

Correct:

```yaml
volumes:
  - ./data:/data
```

Incorrect:

```yaml
volumes:
  - /var/lib/application:/data
```

This guarantees that the entire stack remains encapsulated inside:

```plaintext
/opt/stacks/<app_id>/
```

---

## 4.3 Port Exposure Policy

The `ports:` directive is allowed only for infrastructure services that require direct host access, such as:

- Reverse proxies.
- DNS services.
- VPN services.
- Administrative interfaces.
- Services that must be directly reachable from the host network.

Examples:

- Nginx Proxy Manager.
- AdGuard Home.
- WG-Easy.
- Dockge.
- Portainer.

Regular web applications must not expose ports to the host and should be accessed exclusively through the reverse proxy layer.

---

# 5. Layered Network Isolation Model (Introduced in v1.1)

DockerWarrior follows the principle of **Layered Network Isolation**.

The goal is to enforce the principle of least privilege and reduce the attack surface between independent stacks.

---

## 5.1 Perimeter Services

Services that need to communicate with external components may join:

- The private stack network (`default`).
- Shared global networks, such as:

```plaintext
dw_proxy_network
```

Example:

```plaintext
                 Internet
                     |
                     |
             Nginx Proxy Manager
                     |
             +-------+-------+
             |               |
      dw_proxy_network    default
```

---

## 5.2 Internal Persistence Services

Databases, caches, and internal support services, including:

- MariaDB
- PostgreSQL
- Redis
- Memcached

Must remain exclusively attached to the private stack network.

Correct example:

```yaml
services:

  app:
    networks:
      - default
      - dw_proxy_network

  database:
    networks:
      - default
```

This prevents lateral movement between compromised applications.

---

# 6. env.template File

The `env.template` file acts as the interface between the application package and the DockerWarrior deployment engine.

The following must never be stored in the Git repository:

- Passwords.
- Tokens.
- API keys.
- Administrative secrets.

Example:

```ini
DATABASE_PASSWORD={{SECRET:32}}
TZ={{SYSTEM_TZ}}
```

The deployment engine replaces these placeholders dynamically during installation.

---

# 7. Automatic Secret Management

The DockerWarrior engine provides:

- Cryptographically secure secret generation using OpenSSL.
- Automatic placeholder replacement.
- Automatic `.env` file creation.
- Automatic protection using:

```plaintext
chmod 600
```

This guarantees that secrets are never committed to Git.

---

# 8. Optional Hooks

The scripts:

- `pre_install.sh`
- `post_install.sh`

allow applications to execute custom actions before or after deployment.

Examples:

- Creating special resources.
- Data migrations.
- Application-specific validation.

Rules:

- Must start with:

```bash
#!/usr/bin/env bash
```

- Must be idempotent.
- Must return exit code `0` on success.
- Any critical failure must return a non-zero exit code.

---

# 9. DockerWarrior Architectural Principles

Every package must respect the following principles.

---

## 9.1 Immutable Core

The framework core:

```plaintext
install.sh
lib/core/
lib/ui/
```

must never be modified to add a new application.

---

## 9.2 Declarative Architecture

Adding a new application should only require:

1. Creating a new directory inside `templates/`.
2. Writing `metadata.conf`.
3. Creating `compose.yaml`.
4. Defining `env.template`.
5. Registering the application inside `config/apps.conf`.

No modification of the deployment engine or installer is allowed.

---

## 9.3 Dockge Compatibility

Every generated stack must:

- Be automatically detected by Dockge.
- Be fully manageable through the graphical interface.
- Be restartable without requiring DockerWarrior intervention.

---

# 10. Compliance Certification Checklist

An application package is considered DockerWarrior compliant only if it satisfies all requirements of DW-AppSpec.

Checklist:

- [ ] Valid package directory structure.
- [ ] Correct `metadata.conf`.
- [ ] No secrets stored in the repository.
- [ ] Proper `.env` usage.
- [ ] Relative persistent volumes.
- [ ] Port exposure policy respected.
- [ ] Layered network isolation implemented.
- [ ] Dockge compatibility verified.
- [ ] Idempotent hooks.

---

# 11. Version History

## DW-AppSpec v1.0

Initial official specification introducing:

- Declarative application packaging.
- Generic deployment engine.
- Automatic secret management.
- Dockge integration.

---

## DW-AppSpec v1.1

Security improvements introducing:

- Layered network isolation.
- Strict separation between perimeter services and persistence layers.
- Elimination of unnecessary database exposure.
- Protection against lateral movement between stacks.

---

# Official Declaration

**DW-AppSpec v1.1 is officially declared as the mandatory application development standard for DockerWarrior Core v1.0.**

Any current or future application integrated into the DockerWarrior ecosystem must comply with this specification.