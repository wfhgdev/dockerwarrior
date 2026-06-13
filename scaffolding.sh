#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="serverforge"

echo "🚀 Iniciando el scaffolding para $PROJECT_DIR..."

# 1. Crear la estructura principal de directorios
mkdir -p "$PROJECT_DIR"/{.github/workflows,lib/{core,docker,ui},apps/{core,proxy,services},templates/{dockge,portainer,nginx-proxy-manager,wg-easy,nextcloud,jellyfin,immich,adguard-home,odoo,vaultwarden,limesurvey,fail2ban,mailserver},config,lang,docs}

# 2. Navegar al directorio del proyecto
cd "$PROJECT_DIR"

# 3. Crear archivos principales y scripts CLI
touch install.sh serverforge.sh
chmod +x install.sh serverforge.sh

# 4. Crear archivos de la librería (lib/)
touch lib/core/{system.sh,logger.sh,utils.sh}
touch lib/docker/{install.sh,network.sh}
touch lib/ui/menu.sh
touch lib/security.sh

# 5. Crear archivos de integración de aplicaciones (apps/)
touch apps/core/{dockge.sh,portainer.sh}
touch apps/proxy/{nginx-proxy-manager.sh,wg-easy.sh}
touch apps/services/{nextcloud.sh,jellyfin.sh,immich.sh,adguard-home.sh,odoo.sh,vaultwarden.sh,limesurvey.sh,fail2ban.sh,mailserver.sh}

# 6. Crear plantillas base (templates/)
for app in dockge portainer nginx-proxy-manager wg-easy nextcloud jellyfin immich adguard-home odoo vaultwarden limesurvey fail2ban mailserver; do
    touch "templates/$app/compose.yaml"
    touch "templates/$app/env.template"
done

# 7. Crear archivos de configuración (config/)
touch config/{versions.conf,defaults.conf}

# 8. Crear archivos de idioma (lang/)
touch lang/{en.sh,es.sh}

# 9. Crear archivos de infraestructura y documentación
touch .github/workflows/shellcheck.yml
touch .gitignore LICENSE README.md CONTRIBUTING.md

# 10. Inicializar repositorio Git local
git init > /dev/null 2>&1
echo "node_modules/" >> .gitignore
echo "*.log" >> .gitignore
echo ".env" >> .gitignore

echo "✅ Esqueleto de ServerForge creado exitosamente."
echo "📁 Directorio actual: $(pwd)"
ls -la
