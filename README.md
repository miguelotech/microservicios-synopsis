# Automatización con Bash

Para facilitar el flujo de trabajo de los microservicios Spring, añadí el script `scripts/microservices.sh`. Está pensado para que puedas construir todas las imágenes Docker, levantar los contenedores y consultar su estado/logs sin repetir comandos largos.

## Requisitos

- Docker 24+ con acceso al daemon.
- Docker Compose v2 (`docker compose ...`). Si solo cuentas con `docker-compose`, el script lo detecta y lo usa automáticamente.
- Bash (por ejemplo, desde Git Bash en Windows).

> En Windows el bit de ejecución no se marca automáticamente. Si planeas usar el script desde WSL/Linux ejecuta `chmod +x scripts/microservices.sh` una sola vez.

## Comandos disponibles

```bash
# Construir todas las imágenes (usa IMAGE_TAG=1.0 por defecto)
scripts/microservices.sh build

# Construir solo algunos servicios
scripts/microservices.sh build gateway-service ms-orders

# Levantar toda la plataforma (depura los contenedores en segundo plano)
scripts/microservices.sh up

# Apagar contenedores (puedes pasar flags extra de docker compose, ej. -v)
scripts/microservices.sh down

# Revisar estado/health rápidamente (feature adicional solicitado)
scripts/microservices.sh status

# Seguir los logs de un servicio en vivo (Ctrl+C para salir)
scripts/microservices.sh logs gateway-service
```

### Variables útiles

- `IMAGE_TAG`: etiqueta aplicada a las imágenes en `docker build`. Debe coincidir con las referencias del `docker-compose.yml` (por defecto `1.0`).

Con estos comandos tienes:
1. **Build en un paso:** `scripts/microservices.sh build`.
2. **Arranque completo:** `scripts/microservices.sh up`.
3. **Facilidad extra:** `status` y `logs` para observar rápidamente la salud del entorno sin recordar comandos de Compose.
