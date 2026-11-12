#!/bin/bash
# Runs the Garmin Connect IQ SDK Manager in an Ubuntu 22.04 container.
# Needed on Ubuntu 24.04+ (e.g. 26.04), which no longer ship libwebkit2gtk-4.0.
# SDKs and devices are saved to ~/.Garmin on the host as usual.
#
#   SDKMANAGER_DIR=~/Downloads/connectiq-sdk-manager-linux tools/sdkmanager-docker/run-sdkmanager.sh
HERE="$(dirname "$(readlink -f "$0")")"
SDKM="${SDKMANAGER_DIR:-$HOME/Downloads/connectiq-sdk-manager-linux}"
if [ ! -x "$SDKM/bin/sdkmanager" ]; then
  echo "SDK Manager not found in $SDKM. Download it from developer.garmin.com/connect-iq/sdk and unzip it there,"
  echo "or set SDKMANAGER_DIR to its folder."
  exit 1
fi
if ! docker image inspect ciq-sdkmanager >/dev/null 2>&1; then
  echo "Building the ciq-sdkmanager Docker image (one time, a few minutes)..."
  docker build -t ciq-sdkmanager "$HERE" || exit 1
fi
mkdir -p "$HOME/.Garmin"
xhost +SI:localuser:"$USER" >/dev/null
docker run --rm -it \
  --user "$(id -u):$(id -g)" \
  -e HOME="$HOME" -e DISPLAY="$DISPLAY" -e NO_AT_BRIDGE=1 \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v "$HOME/.Garmin:$HOME/.Garmin" \
  -v "$SDKM:/sdkm" \
  --network host --ipc host \
  ciq-sdkmanager /sdkm/bin/sdkmanager "$@"
xhost -SI:localuser:"$USER" >/dev/null
