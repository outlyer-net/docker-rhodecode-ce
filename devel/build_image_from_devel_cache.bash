#!/bin/bash

# This script builds the docker image by relying on host-cached RhodeCode files
# It passes down any argument to docker build, e.g.
#  $ ./build_image_from_
# IMPORTANT: serve_locally.bash should be run in parallel
# See serve_locally.bash for the reasoning for this

IMAGE_NAME=${IMAGE_NAME:-rhodecode-devel}
SCRIPT_DIR="$(dirname "$0")"
BUILD_CONTEXT=$(realpath "$SCRIPT_DIR/..")/
RHODECODE_INSTALLER_URL="$(grep installer $SCRIPT_DIR/cache/MANIFEST | awk '{print $2}')"

# Try to detect docker's address (to access the host during build)
HOST_IP=$(ip -4 a show  docker0 scope global \
                | sed -e '/inet /!d' \
                | awk '{print $2}' \
                | cut -d/ -f1
)

exec docker build -t "$IMAGE_NAME" \
        --build-arg RHODECODE_MANIFEST_URL="http://$HOST_IP:8000/MANIFEST" \
        --build-arg RHODECODE_INSTALLER_URL="$RHODECODE_INSTALLER_URL" \
        "$@" \
        "$BUILD_CONTEXT"