FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    libwebkit2gtk-4.0-37 libgtk-3-0 libsecret-1-0 libusb-1.0-0 libcurl4 libsm6 libxext6 libxrender1 \
    ca-certificates openjdk-17-jre-headless dbus-x11 fonts-dejavu-core libcanberra-gtk3-module \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends xvfb x11-apps imagemagick xdotool libpulse0 libsdl2-2.0-0 && rm -rf /var/lib/apt/lists/*
