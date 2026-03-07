# Guía de Instalación y Migración Completa: Pterodactyl Custom (Docker)

Esta guía unifica el proceso de migración desde pterodactyl Bare Metal y la instalación limpia en Docker.
**Ruta de trabajo recomendada:** `/srv/pterodactyl` (Todo centralizado).

---

## 🔄 Fase 1: Migración (Solo una vez si se esta migrando a docker el panel), saltar a la fase 1 si se empeiza desde 0

Si ya tienes un panel instalado "a la antigua" (sin Docker) y quieres pasarlo a Docker:

1. **Sube el script de migración al servidor:**
    Sube `migrate_to_docker.sh` a tu servidor (por SFTP o curl).

2. **Ejecuta el script (COMO ROOT):**
    Este script detendrá tus servicios antiguos, hará backup de la BD, moverá los archivos a `/srv/pterodactyl` y ajustará permisos.

    ```bash
    chmod +x migrate_to_docker.sh
    sudo ./migrate_to_docker.sh
    ```

    *Sigue las instrucciones en pantalla. Anota la contraseña de BD que te muestra al final.*

3. **Mover archivos de proyecto:**
    El script preparó la carpeta `/srv/pterodactyl`. Ahora mueve tus archivos de configuración Docker allí:

    ```bash
    # Asumiendo que subiste docker-compose.yml, Dockerfile, entrypoint.sh a tu home (~)
    sudo mv ~/docker-compose.yml /srv/pterodactyl/
    sudo mv ~/Dockerfile /srv/pterodactyl/
    sudo mv ~/entrypoint.sh /srv/pterodactyl/

    # Ve al directorio de trabajo definitivo
    cd /srv/pterodactyl
    ```

---

## 🚀 Fase 2: Instalación Limpia (O continuación de migración)

La instalacion sin migraciones empieza aqui

### 1. Preparación del Sistema

Crea la estructura de carpetas (saltar este paso si se empezo de la fase 1):

```bash
sudo mkdir -p /srv/pterodactyl/var
sudo mkdir -p /srv/pterodactyl/nginx
sudo mkdir -p /srv/pterodactyl/certs
sudo mkdir -p /srv/pterodactyl/logs
sudo mkdir -p /srv/pterodactyl/database
cd /srv/pterodactyl
# (Aquí debes subir o crear tu docker-compose.yml, Dockerfile, entrypoint.sh y .env)
```

### 2. Configuración de Secretos y SSL (CRÍTICO)

1. **Configurar los Certificados SSL (Cloudflare u otros):**
   Para que tu panel utilice HTTPS internamente, el contenedor lee directamente de la ruta `/etc/certs` de tu servidor.
   Asegúrate de colocar tus archivos allí con los nombres correctos:

   ```bash
   sudo mkdir -p /etc/certs
   # Coloca tu certificado y llave privada aquí:
   # /etc/certs/cert.pem
   # /etc/certs/key.pem
   ```

   *Nota: Si utilizas otros nombres, debes renombrarlos a `cert.pem` y `key.pem` o el contenedor no los detectará automáticamente.*

2. **Verifica tu archivo .env:**
    Asegúrate de tener un archivo `.env` en `/srv/pterodactyl/`.
    Asegúrate de que la variable `APP_URL` empiece por `https://` (ej. `APP_URL=https://panel.tudominio.com`).
    Si vienes de migración, el script ya lo puso ahí.
    Si es instalación limpia, crea uno nuevo.

3. **Sincronizar Contraseña de Base de Datos:**
    El `docker-compose.yml` debe tener la MISMA contraseña que el `.env`.

    * **Obtén la contraseña real:**

        ```bash
        grep DB_PASSWORD .env
        ```

    * **Edita el docker-compose:**

        ```bash
        nano docker-compose.yml
        ```

    * **Cambia:** `MYSQL_PASSWORD: "CHANGE_ME"` por la contraseña obtenida.

### 3. Construcción y Despliegue

1. **Permisos:**

    ```bash
    sudo chmod +x entrypoint.sh
    ```

2. **Iniciar Docker:**

    ```bash
    # --build asegura que se use la última versión de tu Dockerfile
    sudo docker compose up -d --build
    ```

3. **Verificar Logs (Espera a que termine):**
    El contenedor hará migraciones e instalará Arix automáticamente al iniciar.

    ```bash
    sudo docker compose logs -f panel
    ```

    *Busca el mensaje: "Iniciando Pterodactyl..."*

---

## 📦 Fase 3: Importar Base de Datos (Solo Migración)

Si migraste, tu base de datos Docker estará vacía al inicio. Tienes que importar el backup que hizo el script.

esta fase es opcional para seguir con la migracion, la instalacion termina en la fase 2

1. **Localiza el backup:**
    El script te dijo dónde quedó (ej. `/root/pterodactyl_backup_FECHA/panel_dump.sql`).

2. **Importar:**

    ```bash
    # Copia el backup al contenedor (Ajusta la ruta del backup según corresponda)
    sudo docker cp /root/pterodactyl_backup_XXXX/panel_dump.sql pterodactyl-database-1:/tmp/backup.sql

    # Importa (Usa la contraseña que configuraste en el paso 2)
    sudo docker exec -it pterodactyl-database-1 sh -c 'mysql -u root -p panel < /tmp/backup.sql'
    ```

---

## 🗑️ Zona de Peligro: Borrar Todo y Empezar de 0

**⚠️ COMANDOS DESTRUCTIVOS** - Úsalos si algo salió muy mal y quieres reiniciar la instalación limpia.

```bash
cd /srv/pterodactyl

# 1. Apagar contenedores
sudo docker compose down

# 2. Borrar volúmenes de datos (BD y archivos del panel)
sudo rm -rf /srv/pterodactyl/database/*
sudo rm -rf /srv/pterodactyl/var/*
sudo rm -rf /srv/pterodactyl/nginx/*
sudo rm -rf /srv/pterodactyl/certs/*
sudo rm -rf /srv/pterodactyl/logs/*

# 3. Limpiar Docker (Opcional)
sudo docker system prune -f
```

Una vez limpio, vuelve al paso "Fase 2: Instalación Limpia".
