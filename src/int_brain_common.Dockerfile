ARG ROS_DISTRO=jazzy

## Get base image
FROM ros:$ROS_DISTRO-ros-base

## Config args
ARG USERNAME=ubuntu
ARG WORKSPACE=/home/$USERNAME/int_brain_ws

## Make ubuntu a sudo user
RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu \
    && chmod 0440 /etc/sudoers.d/ubuntu

## Update system
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get update -y

## Install basic tools
RUN apt-get install --no-install-recommends -y \
    vim \
    bat \
    python3-pip \
    python3-venv \
    net-tools \
    tree

## Install ROS packages
# Install Xacro
RUN apt-get install --no-install-recommends -y \
    ros-$ROS_DISTRO-xacro

# Install ros2 control
RUN apt-get install --no-install-recommends -y \
    ros-$ROS_DISTRO-ros2-control \
    ros-$ROS_DISTRO-ros2-controllers \
    ros-$ROS_DISTRO-rqt-controller-manager

# Install sensor fusion
RUN apt-get install --no-install-recommends -y \
    ros-$ROS_DISTRO-robot-localization

# Install RPLidar SDK
RUN git clone --depth=1 --progress --verbose https://github.com/Slamtec/sllidar_ros2.git -C $WORKSPACE

## Set default shell to bash 
SHELL ["/bin/bash", "-c"]

## Add to groups
RUN usermod -aG dialout $USERNAME
RUN usermod -aG video $USERNAME

## Initialize rosdep
RUN rosdep update

## Set username
USER $USERNAME

## Set variables
ENV ROS_DISTRO=$ROS_DISTRO
ENV ROS_DOMAIN_ID=42
ENV WORKSPACE=$WORKSPACE

## Create workspace
RUN mkdir -p $WORKSPACE

# Convenience scripts
RUN echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> /home/$USERNAME/.bashrc
RUN echo "source $WORKSPACE/install/setup.bash && echo \"Sourced workspace\"" >> /home/$USERNAME/.bashrc

LABEL org.opencontainers.image.authors="eccentricOrange, exMachina316"
LABEL org.opencontainers.image.source="https://github.com/eccentricOrange/int-brain-containers"
