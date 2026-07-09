# ROSCon 2026 ros2_control Workshop — Docker environment

Runs the Open Duck Mini MuJoCo demo
(`ros2 launch ros2_control_demo_example_18 example_18_mujoco.launch.py`)
out of the box on both **NVIDIA** and **Intel/AMD** GPUs, using **Zenoh**
(`rmw_zenoh_cpp`) as the ROS 2 middleware.

## Prerequisites

- [Docker + Docker Compose](https://docs.docker.com/compose/install/linux/).
- **NVIDIA hosts only:** the
  [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).
- An **X11** desktop session (the MuJoCo GUI uses OpenGL/GLFW over X11).

## Quick start

```bash
# from the repo root
./run.sh          # auto-detects NVIDIA vs Mesa, allows X access, starts the container
```

Add this handy alias to your host `~/.bashrc`:

```bash
echo 'alias rc="docker exec -it ros2_control_roscon26 bash"' >> ~/.bashrc
```

Running the demo needs **three terminals**, each attached to the container with
`rc`. Aliases (`z`, `demo`, `teleop`) are preconfigured in the container.

```bash
# Terminal 1 — Zenoh router
z

# Terminal 2 — MuJoCo simulation + controllers
demo

# Terminal 3 — drive the duck forward
teleop
```

## GPU selection

`run.sh` picks the backend automatically. To be explicit:

```bash
# Intel / AMD (Mesa via /dev/dri)
docker compose -f docker-compose.yaml up -d

# NVIDIA (NVIDIA Container Toolkit)
docker compose -f docker-compose.yaml -f docker-compose.nvidia.yaml up -d
```

## Building / pulling

```bash
./run.sh build     # build locally
# or pull the published image (default in docker-compose.yaml):
docker compose -f docker-compose.yaml pull
```

## Restart / rebuild

```bash
./run.sh          # restart a stopped container, or recreate it after a rebuild
./run.sh down     # stop and remove the container
```

## Troubleshooting the GUI

- **Blank / black MuJoCo window:** the GL context is not reaching a real GPU
  display.
  - Run `xhost +local:root` on the host (once per boot). `run.sh` does this.
  - NVIDIA: confirm `docker exec ros2_control_roscon26 nvidia-smi` works and
    that `NVIDIA_DRIVER_CAPABILITIES=all` (includes `graphics`).
  - Intel/AMD: confirm `/dev/dri` exists on the host and
    `docker exec ros2_control_roscon26 glxinfo -B` reports your GPU.
  - Remote/VNC/screen-share sessions cannot show NVIDIA *direct-rendered*
    OpenGL — run at the physical display, or use VirtualGL/TurboVNC.
- **`glxinfo` shows `llvmpipe`:** you are on software rendering — the GPU is not
  passed through. Re-check the toolkit (NVIDIA) or `/dev/dri` (Mesa).

## Dependencies

Source packages are listed in [`deps.repos`](deps.repos) and built in the
image. Change a `version:` there to test an in-review branch, then rebuild.
