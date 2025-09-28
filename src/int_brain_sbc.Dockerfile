FROM ghcr.io/eccentricorange/int_brain_common:aarch64-dev0.12

USER root

## Update system
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get update -y

## install hardware-specific packages
RUN apt-get install --no-install-recommends -y \
    python3-lgpio \
    python3-gpiozero \
    python3-smbus \
    i2c-tools

USER ubuntu
WORKDIR $WORKSPACES

LABEL org.opencontainers.image.authors="eccentricOrange, exMachina316"
LABEL org.opencontainers.image.source="https://github.com/eccentricOrange/int-brain-containers"
