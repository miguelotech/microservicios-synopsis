#!/usr/bin/env bash
# Script maestro para construir imagenes y manejar docker-compose del proyecto.
set -euo pipefail  # salir ante errores, variables no declaradas y pipes fallidos

# Directorio raiz y recursos base reutilizados por los comandos.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$ROOT_DIR/docker-compose.yml"
# Permite cambiar la etiqueta sin editar el script: IMAGE_TAG=2.0 scripts/microservices.sh build.
IMAGE_TAG="${IMAGE_TAG:-1.0}"

# Servicios Spring Boot que tienen Dockerfile propio dentro del repo.
SERVICES=(
  ms-config-server
  registry-service
  gateway-service
  ms-product
  ms-orders
)

# Formatea mensajes con timestamp para distinguir etapas.
log() {
  printf '\n[%s] %s\n' "$(date '+%H:%M:%S')" "$*"
}

# Reporta un error al usuario y corta la ejecucion.
error() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

# Asegura que una herramienta requerida exista en PATH.
require_command() {
  command -v "$1" >/dev/null 2>&1 || error "El comando '$1' es requerido pero no esta instalado."
}

# Determina si usar 'docker compose' (v2) o el binario legado 'docker-compose'.
detect_compose() {
  if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD=(docker compose)
  elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD=(docker-compose)
  else
    error "Necesitas Docker Compose v2 (docker compose) u obtener docker-compose en tu PATH."
  fi
}

# Normaliza la lista de servicios objetivo y valida que existan.
resolve_services() {
  if [[ "$#" -gt 0 ]]; then
    target=("$@")
  else
    target=("${SERVICES[@]}")
  fi

  for service in "${target[@]}"; do
    found=false
    for known in "${SERVICES[@]}"; do
      if [[ "$service" == "$known" ]]; then
        found=true
        break
      fi
    done
    [[ "$found" == false ]] && error "Servicio desconocido: $service"
  done

  printf '%s\n' "${target[@]}"
}

# Recorre los servicios y construye sus imagenes Docker.
build_images() {
  require_command docker
  local targets=()
  mapfile -t targets < <(resolve_services "$@")

  for service in "${targets[@]}"; do
    local context="$ROOT_DIR/$service"
    local image="$service:$IMAGE_TAG"

    [[ -f "$context/Dockerfile" ]] || error "No encuentro Dockerfile para $service en $context."

    log "Construyendo imagen ${image}"
    docker build --pull -t "$image" "$context"
  done

  log "Todas las imagenes se construyeron correctamente."
}

# Levanta los contenedores declarados en docker-compose.yml en background.
compose_up() {
  require_command docker
  detect_compose
  log "Levantando toda la plataforma en segundo plano"
  "${COMPOSE_CMD[@]}" -f "$COMPOSE_FILE" up -d
  log "Servicios arriba. Usa './scripts/microservices.sh status' para revisar el estado."
}

# Apaga los contenedores; admite flags extra como '-v' para borrar volumenes.
compose_down() {
  require_command docker
  detect_compose
  log "Apagando contenedores y redes"
  "${COMPOSE_CMD[@]}" -f "$COMPOSE_FILE" down "$@"
}

# Muestra el estado actual (similar a docker compose ps).
compose_status() {
  require_command docker
  detect_compose
  log "Estado actual de los contenedores"
  "${COMPOSE_CMD[@]}" -f "$COMPOSE_FILE" ps
}

# Sigue los logs de un servicio especifico para depurar rapido.
compose_logs() {
  require_command docker
  detect_compose
  if [[ "$#" -lt 1 ]]; then
    error "Debes indicar el servicio para seguir logs. Ej: logs gateway-service"
  fi
  local service="$1"
  log "Mostrando logs en vivo de $service (Ctrl+C para salir)"
  "${COMPOSE_CMD[@]}" -f "$COMPOSE_FILE" logs -f "$service"
}

# Muestra la ayuda resumida del script.
usage() {
  cat <<EOF
Uso:
  scripts/microservices.sh build [servicio ...]  Construye todas las imagenes o solo las que indiques.
  scripts/microservices.sh up                    Levanta todos los contenedores con Docker Compose.
  scripts/microservices.sh down [args]           Apaga la plataforma (admite flags de compose).
  scripts/microservices.sh status                Muestra el estado actual de los servicios.
  scripts/microservices.sh logs <servicio>       Sigue los logs de un servicio especifico.

Variables utiles:
  IMAGE_TAG   Cambia la etiqueta usada para docker build (por defecto 1.0 para empatar con docker-compose.yml).
EOF
}

# Punto de entrada y despacho de subcomandos.
main() {
  local cmd="${1:-}"
  shift || true

  case "$cmd" in
    build) build_images "$@" ;;
    up) compose_up ;;
    down) compose_down "$@" ;;
    status) compose_status ;;
    logs) compose_logs "$@" ;;
    ""|-h|--help|help) usage ;;
    *) usage && error "Comando desconocido: $cmd" ;;
  esac
}

main "$@"
