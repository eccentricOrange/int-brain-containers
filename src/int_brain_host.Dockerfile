FROM ghcr.io/eccentricorange/int_brain_common:amd64-dev0.5

USER root

# Install Gz sim
RUN apt-get install --no-install-recommends -y \
    ros-$ROS_DISTRO-ros-gz-sim \
    ros-$ROS_DISTRO-ros-gz-interfaces \
    ros-$ROS_DISTRO-ros-gz-bridge \
    ros-$ROS_DISTRO-gz-ros2-control

# Install teleop packages
RUN apt-get install --no-install-recommends -y \
    ros-$ROS_DISTRO-teleop-twist-joy \
    ros-$ROS_DISTRO-teleop-twist-keyboard \
    ros-$ROS_DISTRO-joy

# Install Utils
RUN apt-get install --no-install-recommends -y \
    ros-$ROS_DISTRO-rviz2 \
    ros-$ROS_DISTRO-rviz-imu-plugin \
    ros-$ROS_DISTRO-joint-state-publisher-gui \
    ros-$ROS_DISTRO-plotjuggler-ros

USER ubuntu
WORKDIR $WORKSPACE

LABEL org.opencontainers.image.authors="eccentricOrange, exMachina316"
LABEL org.opencontainers.image.source="https://github.com/eccentricOrange/int-brain-containers"
