@echo off
REM ──────────────────────────────────────────────────────────────
REM Pterodactyl Custom Panel - Script de inicio (Windows)
REM Uso: start.bat
REM ──────────────────────────────────────────────────────────────

echo === Pterodactyl Custom Panel - Inicio ===

REM 1. Crear .env desde template si no existe
if not exist .env (
    echo [1/3] Generando .env desde .env.example...
    copy .env.example .env >nul

    REM Generar APP_KEY con python (disponible en la mayoria de sistemas Windows)
    where python >nul 2>&1
    if %errorlevel% equ 0 (
        for /f "delims=" %%i in ('python -c "import base64,os; print('base64:' + base64.b64encode(os.urandom(32)).decode())"') do set APP_KEY=%%i
        powershell -Command "(Get-Content .env) -replace '^APP_KEY=.*', 'APP_KEY=%APP_KEY%' | Set-Content .env"
        echo     APP_KEY generado correctamente.
    ) else (
        echo ADVERTENCIA: Python no encontrado. El entrypoint generara APP_KEY automaticamente.
    )
) else (
    echo [1/3] .env ya existe, saltando.
)

REM 2. Crear directorios de datos
echo [2/3] Creando directorios de datos...
if not exist data\database mkdir data\database
if not exist data\var mkdir data\var
if not exist data\logs mkdir data\logs
if not exist data\certs mkdir data\certs

REM 3. Levantar contenedores
echo [3/3] Levantando contenedores...
docker compose up -d

echo.
echo === Panel iniciado ===
echo URL:      http://localhost
echo.
echo Esperando a que el panel arranque (migraciones + Blueprint)...
echo Puedes ver el progreso con: docker compose logs -f panel
echo.
echo Una vez listo, crea tu usuario admin con:
echo   docker compose exec panel php artisan p:user:make
