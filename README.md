# Pterodactyl Panel Custom - Docker & Blueprint

Este proyecto toma la imagen oficial de Docker de [Pterodactyl Panel](https://pterodactyl.io/) y la extiende con automatizaciones para el despliegue, migración y personalización del panel mediante [Blueprint](https://blueprint.zip/).

## Inicio Rápido

### Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows/Mac) o Docker Engine (Linux)
- Git

### Instalación

```bash
git clone https://github.com/DANK1775/pterodactyl-custom.git
cd pterodactyl-custom
```

**Windows:**
```
start.bat
```

**Linux / Mac:**
```bash
bash start.sh
```

Esto automáticamente:
1. Genera `.env` con un `APP_KEY` único desde `.env.example`
2. Crea los directorios de datos (`data/`)
3. Levanta los contenedores con `docker compose up -d`

### Primer acceso

Espera a que el panel termine de arrancar (migraciones + Blueprint):

```bash
docker compose logs -f panel
```

Cuando veas `Iniciando Pterodactyl...`, crea tu usuario administrador:

```bash
docker compose exec panel php artisan p:user:make
```

Accede al panel en **http://localhost**.

---

## Estructura del Proyecto

```
pterodactyl-custom/
├── .env.example        # Template de configuración (se copia a .env)
├── .gitattributes      # Fuerza LF en scripts (evita problemas CRLF en Windows)
├── docker-compose.yml  # Orquestación de servicios
├── Dockerfile          # Imagen custom del panel
├── entrypoint.sh       # Bootstrap: migraciones, Blueprint, assets, SSL
├── bpinstaller.sh      # Instalador de Blueprint framework
├── start.sh            # Script de inicio (Linux/Mac)
├── start.bat           # Script de inicio (Windows)
├── data/               # Datos persistentes (NO se sube al repo)
│   ├── database/       # MariaDB
│   ├── var/            # Archivos del panel
│   ├── logs/           # Logs de Laravel
│   └── certs/          # Certificados SSL (opcional)
```

### Servicios

| Servicio | Imagen | Puerto |
|----------|--------|--------|
| panel | ghcr.io/dank1775/pterodactyl-custom:latest | 80, 443 |
| database | mariadb:10.5 | 3306 (interno) |
| cache | redis:alpine | 6379 (interno) |

---

## Configuración

### Variables de Entorno

El archivo `.env` es la fuente de verdad para Laravel. Las variables principales:

| Variable | Default | Descripción |
|----------|---------|-------------|
| `APP_URL` | `http://localhost` | URL pública del panel |
| `APP_KEY` | (auto-generado) | Clave de encriptación |
| `DB_PASSWORD` | `pterodactyl_secret_pw` | Contraseña de la base de datos |
| `APP_TIMEZONE` | `UTC` | Zona horaria |

### SSL / HTTPS

Para habilitar SSL, coloca tus certificados en `data/certs/`:

```
data/certs/cert.pem      # Certificado
data/certs/key.pem       # Llave privada
```

El entrypoint detecta y configura Nginx automáticamente. También acepta `fullchain.pem` + `privkey.pem`.

Actualiza `APP_URL` en `.env` a `https://tu-dominio.com`.

---

## Migración desde Bare-metal

Si ya tienes un panel instalado sin Docker, consulta la guía de migración:

**[Ver Guía de Migración (README_INSTALL.md)](README_INSTALL.md)**

---

## Características

- **Auto-bootstrap**: Un solo comando para levantar todo desde un clone fresco
- **Blueprint pre-instalado**: Framework de extensiones listo para usar
- **Entrypoint inteligente**: Genera `.env` y `APP_KEY` si faltan, ejecuta migraciones, instala Blueprint y publica assets automáticamente
- **Compatible Windows/Linux/Mac**: Scripts de inicio para cada plataforma + `.gitattributes` para line endings
- **SSL auto-configurado**: Detecta certificados en `data/certs/` y configura Nginx

### Mejoras del instalador Blueprint (PR #571)

- Validación de dependencias (Node.js 20+, Yarn)
- Descargas con timeouts y fallbacks
- Análisis JSON con `jq` (fallback a grep/cut)
- Verificación de archivos descargados
- Permisos correctos post-instalación

---

## Comandos Útiles

```bash
# Ver logs en tiempo real
docker compose logs -f panel

# Reiniciar panel
docker compose restart panel

# Crear usuario admin
docker compose exec panel php artisan p:user:make

# Entrar al contenedor
docker compose exec panel sh

# Parar todo
docker compose down

# Parar y borrar datos (DESTRUCTIVO)
docker compose down && rm -rf data/
```

---

## Tareas Pendientes

- [ ] Hardening de seguridad para producción (permisos, variables sensibles)
- [ ] Soporte para contraseñas de BD personalizables desde el script de inicio
