# Pterodactyl Panel Custom - Docker & Blueprint

Este proyecto toma la imagen oficial de Docker de [Pterodactyl Panel](https://pterodactyl.io/) y la extiende agregando automatizaciones clave para el despliegue y migracion, facilitando la transición y personalización del panel.

## 🚀 ¿De qué trata este proyecto?

El objetivo principal es simplificar el despliegue y proporcionar herramientas para facilitar el CI/CD y mantencion del panel

este repo tiene las siguientes automatizaciones:

- **Migración desde Bare-metal a Docker**: Incluye scripts diseñados para tomar toda la base de datos de una instalación de Pterodactyl directa en un servidor (bare-metal) y portarla automáticamente al entorno seguro y aislado de Docker.
- **Auto-instalación de Blueprint**: Una vez que el panel se instaló y configuró, el contenedor se encarga de instalar automáticamente el framework [Blueprint](https://blueprint.zip/), dejándolo listo para que puedas instalar modificaciones, temas y addons sin esfuerzo.
  - **Mejoras integradas desde PR #571**: Instalación robusta con manejo de errores mejorado, validación de dependencias (Node.js 20, Yarn), descarga con timeouts y fallbacks, y verificación de archivos.
- **Personalización lista para usar**: Scripts como `entrypoint.sh` se encargan de orquestar el despliegue, preparando las migraciones de base de datos e instalando las utilidades antes de arrancar el servidor web.

## ⚠️ Tareas Pendientes y Mejoras (To-Do)

El proyecto aún se encuentra en desarrollo en áreas de seguridad y exposición a internet. Faltan por arreglar o implementar las siguientes características:

- [ ] **Configuración de TLS y SSL**: Faltan por configurar adecuadamente los certificados SSL/TLS para cifrar el tráfico web (HTTPS).
- [ ] **Hardening y Seguridad**: Es imperativo mejorar la seguridad general del contenedor, revisar los permisos, variables de entorno y la configuración de los accesos a los volúmenes para tener un entorno 100% apto para producción.

## 🎯 Mejoras Recientes - Integración PR #571

Se han integrado las mejoras del [PR #571 de pterodactyl-installer](https://github.com/pterodactyl-installer/pterodactyl-installer/pull/571) para la instalación de Blueprint:

### Mejoras Implementadas:
- ✅ **Validación de dependencias robusta**: Verifica Node.js 20+ y Yarn antes de la instalación
- ✅ **Descarga con manejo de errores**: Timeouts configurables (30s conexión, 300s descarga)
- ✅ **Análisis JSON mejorado**: Usa `jq` cuando está disponible, con fallback a grep/cut
- ✅ **URL de fallback**: Si falla la detección de la última versión, usa URL directa
- ✅ **Verificación de archivos**: Valida que los archivos descargados no estén vacíos
- ✅ **Instalación de producción**: Usa `yarn install --production` para dependencias mínimas
- ✅ **Permisos correctos**: Establece ownership apropiado después de la instalación
- ✅ **Mejores mensajes de error**: Mensajes claros y descriptivos con emojis

### Archivos Modificados:
- `bpinstaller.sh`: Lógica de instalación mejorada basada en el PR
- `Dockerfile`: Agregado `jq` para análisis JSON robusto
- `entrypoint.sh`: Flujo mejorado con mensajes más claros

## 📖 Instrucciones de Uso y Configuración

Para aprender a instalar este proyecto, configurar tus contenedores con `docker-compose.yml` o utilizar los scripts de migración de la base de datos, revisa la guía adjunta:

👉 **[Ver Guía de Instalación (README_INSTALL.md)](README_INSTALL.md)**
