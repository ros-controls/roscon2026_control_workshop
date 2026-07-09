#!/usr/bin/env bash
# Start the workshop container, auto-selecting the GPU backend (NVIDIA toolkit,
# else Mesa via /dev/dri).
#
#   ./run.sh          # start
#   ./run.sh build    # (re)build the image
#   ./run.sh down     # stop and remove
set -euo pipefail
cd "$(dirname "$0")"

COMPOSE=(-f docker-compose.yaml)
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
    echo ">>> NVIDIA GPU detected: enabling NVIDIA runtime."
    COMPOSE+=(-f docker-compose.nvidia.yaml)
else
    echo ">>> No NVIDIA GPU detected: using Mesa (Intel/AMD) via /dev/dri."
fi

# Allow the container to draw on the host X server (once per boot is enough).
xhost +local:root >/dev/null 2>&1 || echo ">>> Could not run 'xhost' (not on X11?); GUI apps may not display."

name=ros2_control_roscon26
cmd="${1:-up}"
case "$cmd" in
    up|"")   docker compose "${COMPOSE[@]}" up -d
             echo ">>> Attach with: docker exec -it ${name} bash" ;;
    build)   docker compose "${COMPOSE[@]}" build ;;
    down)    docker compose "${COMPOSE[@]}" down 2>/dev/null || true
             docker rm -f "${name}" >/dev/null 2>&1 || true ;;
    *)       docker compose "${COMPOSE[@]}" "$@" ;;
esac
