# Guía de Instalación y Gestión: Pterodactyl Custom (Docker)

Este documento detalla los pasos para instalar, configurar y administrar tu panel Pterodactyl personalizado con Docker (incluye Blueprint y Arix Theme).

---

## 🗑️ Guía de Limpieza Total (Empezar de 0)

**⚠️ ADVERTENCIA:** Estos comandos borrarán TODOS los datos (base de datos, configuraciones, certificados) de la instalación actual. Asegúrate de tener backups.

1. **Ir al directorio del proyecto:**

    ```bash
    cd ~/pterodactyl
    ```

2. **Detener y eliminar contenedores y redes:**

    ```bash
    sudo docker compose down
    ```

3. **Eliminar volúmenes de datos persistentes:**
    Aquí es donde viven la base de datos y los archivos del panel.

    ```bash
    # Borrar la base de datos
    sudo rm -rf /srv/pterodactyl/database/*

    # Borrar archivos del panel (logs, configuración nginx, certificados, etc.)
    sudo rm -rf /srv/pterodactyl/var/*
    sudo rm -rf /srv/pterodactyl/nginx/*
    sudo rm -rf /srv/pterodactyl/certs/*
    sudo rm -rf /srv/pterodactyl/logs/*

    # Opcional: Borrar el .env si quieres reconfigurarlo desde cero
    # sudo rm /srv/pterodactyl/.env
    ```

4. **Limpiar sistema Docker (Opcional pero recomendado):**

    ```bash
    sudo docker system prune -a -f
    ```

---

## 🚀 Guía de Instalación desde Cero

### 1. Preparación del Sistema

1. Crea el directorio de trabajo en tu usuario:

    ```bash
    mkdir -p ~/pterodactyl
    cd ~/pterodactyl
    ```

2. Crea los directorios de persistencia (Volúmenes):

    ```bash
    sudo mkdir -p /srv/pterodactyl/var
    sudo mkdir -p /srv/pterodactyl/nginx
    sudo mkdir -p /srv/pterodactyl/certs
    sudo mkdir -p /srv/pterodactyl/logs
    sudo mkdir -p /srv/pterodactyl/database
    ```

### 2. Archivos Necesarios

Debes tener los siguientes archivos en `~/pterodactyl`:

* `docker-compose.yml`
* `Dockerfile`
* `entrypoint.sh`
* `.env` (Este archivo contiene tus secretos).

**Si vienes de una migración:**
Copia el `.env` generado por el script de migración a esta carpeta y también a la ruta de volúmenes:

```bash
# Copia a la carpeta actual para que docker-compose lo lea
cp /srv/pterodactyl/.env .

# Asegura que exista en el volumen (crítico para artisan)
sudo cp .env /srv/pterodactyl/.env
```

### 3. Configuración de Contraseñas (CRÍTICO)

1. Abre tu archivo `.env` y busca la contraseña de la base de datos:

    ```bash
    grep DB_PASSWORD .env
    ```

    *(Copia el valor que aparece después del signo =)*

2. Edita el `docker-compose.yml`:

    ```bash
    nano docker-compose.yml
    ```

3. Busca la sección `x-common` -> `database` y reemplaza `"CHANGE_ME"` por la contraseña que copiaste:

    ```yaml
    MYSQL_PASSWORD: &db-password "TU_CONTRASEÑA_DEL_ENV"
    ```

4. Guarda (`Ctrl+O`, `Enter`) y sal (`Ctrl+X`).

### 4. Construcción y Despliegue

1. Dale permisos de ejecución al entrypoint:

    ```bash
    sudo chmod +x entrypoint.sh
    ```

2. Construye la imagen y levanta los contenedores:

    ```bash
    # El flag --build fuerza a reconstruir la imagen con los últimos cambios del Dockerfile
    sudo docker compose up -d --build
    ```

3. Verifica el estado:

    ```bash
    sudo docker compose ps
    ```

### 5. Monitoreo de Primera Ejecución (Importante)

El contenedor realizará tareas automáticas al iniciar (migraciones, instalación de Arix, etc.). Sigue el proceso:

```bash
sudo docker compose logs -f panel
```

**Debes esperar hasta ver:** `Iniciando Pterodactyl...`.
Si ves errores de conexión a SQL, revisa el paso 3.

---

## 📦 Restaurar Backup de Base de Datos (Si migraste)

Como la base de datos se crea vacía en una instalación limpia, debes importar tus datos antiguos.

1. Asegúrate de que el panel ya inició al menos una vez (para que cree la estructura básica).
2. Copia tu archivo `.sql` al contenedor de base de datos:

    ```bash
    # Asumiendo que tu backup se llama panel_dump.sql y está en la carpeta actual
    sudo docker cp panel_dump.sql pterodactyl-database-1:/tmp/backup.sql
    ```

3. Importa el backup:

    ```bash
    # Te pedirá la contraseña (la que pusiste en el paso 3)
    sudo docker exec -it pterodactyl-database-1 sh -c 'mysql -u root -p panel < /tmp/backup.sql'
    ```

---

## 🛠️ Comandos de Mantenimiento

**Reiniciar el panel:**

```bash
sudo docker compose restart panel
```

**Ejecutar comandos de Artisan (Pterodactyl):**

```bash
sudo docker compose exec panel php artisan [comando]
# Ejemplo: Crear usuario admin
sudo docker compose exec panel php artisan p:user:make
# Ejemplo: Limpiar caché
sudo docker compose exec panel php artisan optimize:clear
```
