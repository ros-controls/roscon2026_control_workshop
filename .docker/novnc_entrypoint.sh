#!/bin/bash
# Entrypoint: starts a virtual X display (Xvfb), a minimal window manager,
# a VNC server bound to it, and noVNC (browser client) in front of it.
#
# Browser access:   http://localhost:6080/vnc.html
# Direct VNC view:  localhost:5900 (any VNC client)
#
# Set USE_HOST_DISPLAY=1 to bypass all of this and use the DISPLAY passed
# from the host via the mounted X11 socket instead.

set -e

source "/opt/ros/${ROS_DISTRO}/setup.bash"
# Optional in dev images where the colcon layer was skipped.
[ -f "${ROS_WS:-/root/workshop_ws}/install/setup.bash" ] \
    && source "${ROS_WS:-/root/workshop_ws}/install/setup.bash" || true

export DISPLAY="${DISPLAY:-:99}"

start_novnc() {
    # Clear stale X lock/socket left over from a previous run. Never fatal:
    # e.g. /tmp/.X11-unix may be a host mount that disallows unlink (macOS).
    rm -f /tmp/.X99-lock 2>/dev/null || true
    rm -f /tmp/.X11-unix/X99 2>/dev/null || true

    echo "[novnc-entrypoint] Starting Xvfb on ${DISPLAY} (${SCREEN_GEOMETRY})"
    Xvfb "${DISPLAY}" -screen 0 "${SCREEN_GEOMETRY}" -nolisten tcp &
    # Wait until the X server accepts connections.
    for _ in $(seq 1 20); do
        xdpyinfo -display "${DISPLAY}" >/dev/null 2>&1 && break
        sleep 0.25
    done

    echo "[novnc-entrypoint] Starting fluxbox window manager"
    fluxbox >/dev/null 2>&1 &

    echo "[novnc-entrypoint] Starting x11vnc on port ${VNC_PORT}"
    x11vnc -display "${DISPLAY}" -nopw -forever -shared -xkb \
           -rfbport "${VNC_PORT}" -bg -quiet -o /tmp/x11vnc.log

    echo "[novnc-entrypoint] Starting noVNC (websockify) on port ${NOVNC_PORT}"
    websockify --daemon --web=/usr/share/novnc "${NOVNC_PORT}" "localhost:${VNC_PORT}"

    echo "[novnc-entrypoint] noVNC ready -> http://localhost:${NOVNC_PORT}/vnc.html"
}

if [[ "${USE_HOST_DISPLAY:-0}" == "1" ]]; then
    # Use whatever DISPLAY the host passed through the mounted X11 socket.
    echo "[novnc-entrypoint] Using host display ${DISPLAY} (noVNC disabled)"
else
    # Ignore any inherited DISPLAY (e.g. macOS XQuartz paths) and always
    # render into our own virtual display.
    export DISPLAY=":99"
    start_novnc
fi

exec "$@"
