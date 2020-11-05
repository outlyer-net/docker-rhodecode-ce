#!/bin/bash

# This script builds the docker image by relying on host-cached RhodeCode files
# It passes down any argument to docker build, e.g.
#  $ ./build_image_from_
# IMPORTANT: serve_locally.bash should be run in parallel
# See serve_locally.bash for the reasoning for this

IMAGE_NAME=${IMAGE_NAME:-rhodecode-devel}
SCRIPT_DIR="$(dirname "$0")"
BUILD_CONTEXT=$(realpath "$SCRIPT_DIR/..")

exec docker build -t "$IMAGE_NAME" \
        --build-arg RHODECODE_MANIFEST_URL="http://localhost:8000/MANIFEST" \
        "$@" \
        "$BUILD_CONTEXT"