# syntax=docker/dockerfile:1
ARG ROS_DISTRO=jazzy
FROM ros:${ROS_DISTRO}-ros-base AS roscon-workshop

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO
ARG DEBIAN_FRONTEND=noninteractive

# OpenGL/GLFW runtime for the MuJoCo GUI and off-screen rendering.
# glvnd dispatches to the NVIDIA driver (injected by the NVIDIA container
# runtime) or to Mesa (Intel/AMD via /dev/dri); libglfw3 pulls the needed X11 libs.
RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y --no-install-recommends \
      libgl1 \
      libegl1 \
      libglx-mesa0 \
      libgl1-mesa-dri \
      libegl-mesa0 \
      libgbm1 \
      libglfw3 \
      mesa-utils \
      ros-${ROS_DISTRO}-plotjuggler \
      ros-${ROS_DISTRO}-plotjuggler-ros \
      ros-${ROS_DISTRO}-rmw-zenoh-cpp \
    && rm -rf /var/lib/apt/lists/*

# Use Zenoh as the ROS 2 middleware for the workshop.
ENV RMW_IMPLEMENTATION=rmw_zenoh_cpp

# Expose the NVIDIA GPU when the NVIDIA container runtime is used; no effect otherwise.
ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=all

ENV ROS_WS=/root/workshop_ws
RUN mkdir -p ${ROS_WS}/src
WORKDIR ${ROS_WS}

# Source-built dependencies.
COPY deps.repos /tmp/deps.repos
RUN vcs import src < /tmp/deps.repos

# The workshop repo's own packages.
COPY . src/roscon2026_control_workshop

# Resolve deps only for example_18 and its dependencies.
RUN apt-get update \
    && rosdep update --rosdistro ${ROS_DISTRO} \
    && rosdep install -iy --rosdistro ${ROS_DISTRO} --from-paths \
         src/mujoco_ros2_control \
         src/onnxruntime_vendor \
         src/ros2_control_demos/example_18 \
         src/ros2_control_demos/ros2_control_demo_description \
         src/roscon2026_control_workshop \
    && rm -rf /var/lib/apt/lists/*

# Build example_18 and its workspace dependencies; capped parallelism bounds build memory.
RUN source /opt/ros/${ROS_DISTRO}/setup.bash \
    && MAKEFLAGS="-j2" colcon build \
         --packages-up-to ros2_control_demo_example_18 \
         --parallel-workers 1 \
         --symlink-install \
         --cmake-args -DCMAKE_BUILD_TYPE=Release

# Interactive shell UX.
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc \
    && echo "source ${ROS_WS}/install/setup.bash" >> ~/.bashrc \
    && echo "alias s='source ${ROS_WS}/install/setup.bash'" >> ~/.bashrc \
    && echo "alias cb='MAKEFLAGS=-j2 colcon build --packages-up-to ros2_control_demo_example_18 --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release'" >> ~/.bashrc \
    && echo "alias z='ros2 run rmw_zenoh_cpp rmw_zenohd'" >> ~/.bashrc \
    && echo "alias demo='ros2 launch ros2_control_demo_example_18 example_18_mujoco.launch.py'" >> ~/.bashrc \
    && echo "alias teleop='python3 \$(ros2 pkg prefix ros2_control_demo_example_18)/share/ros2_control_demo_example_18/launch/test_motions.py'" >> ~/.bashrc \
    && echo 'export RCUTILS_COLORIZED_OUTPUT=1' >> ~/.bashrc
ENV TERM=xterm-color
