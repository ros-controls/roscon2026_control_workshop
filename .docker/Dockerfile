# syntax=docker/dockerfile:1
ARG ROS_DISTRO=lyrical
FROM ros:${ROS_DISTRO}-ros-base AS roscon-workshop

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG ROS_DISTRO
ARG DEBIAN_FRONTEND=noninteractive

# Use ROS 2 testing apt source to get latest ros-controls releases independent of a distro sync
RUN apt-get update && apt-get install -y --no-install-recommends ros2-testing-apt-source \
    && rm -rf /var/lib/apt/lists/*

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
      # ros-${ROS_DISTRO}-plotjuggler-ros \
      ros-${ROS_DISTRO}-rmw-zenoh-cpp \
      ros-${ROS_DISTRO}-teleop-twist-keyboard \
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
    && rosdep install --ignore-src -iy --rosdistro ${ROS_DISTRO} --from-paths \
         src/ros2_control_demos/example_18 \
         src/ros2_control_demos/ros2_control_demo_description \
         src/roscon2026_control_workshop \
         src/plotjuggler_ros \
         src/pal \
         --skip-keys="pal_gazebo_worlds" \
    && rm -rf /var/lib/apt/lists/*

# Build example_18 and its workspace dependencies; capped parallelism bounds build memory.
RUN source /opt/ros/${ROS_DISTRO}/setup.bash \
    && MAKEFLAGS="-j2" colcon build \
         --packages-up-to ros2_control_demo_example_18 plotjuggler_ros kangaroo_mujoco kangaroo_description kangaroo_moveit_config pal_policy_deployer pal_policy_inferer \
         --parallel-workers 1 \
         --symlink-install \
         --cmake-args -DCMAKE_BUILD_TYPE=Release

# Interactive shell UX.
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc \
    && echo "source ${ROS_WS}/install/setup.bash" >> ~/.bashrc \
    && echo "alias s='source ${ROS_WS}/install/setup.bash'" >> ~/.bashrc \
    && echo "alias cb='MAKEFLAGS=-j2 colcon build --packages-up-to ros2_control_demo_example_18 --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release'" >> ~/.bashrc \
    && echo "alias z='ros2 run rmw_zenoh_cpp rmw_zenohd'" >> ~/.bashrc \
    && echo "alias sim='ros2 launch kangaroo_mujoco kangaroo_mujoco.launch.py'" >> ~/.bashrc \
    && echo "alias demo='ros2 launch pal_policy_deployer kang_mjlab_policy_deployer.launch.py'" >> ~/.bashrc \
    && echo "alias teleop='ros2 run teleop_twist_keyboard teleop_twist_keyboard'" >> ~/.bashrc \
    && echo 'export RCUTILS_COLORIZED_OUTPUT=1' >> ~/.bashrc
ENV TERM=xterm-color
