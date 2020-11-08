#!/bin/bash

set -xe

# Avoid hammering RhodeCode's servers unnecessarily and waiting for downloads
#  by caching them and serving locally
# Files are only downloaded when this script is invoked if they don't already
#  exist, no further sanity checks are made

cd "$(dirname "$0")"

RC_VERSION=$(grep 'ARG RC_VERSION=' ../Dockerfile | cut -d= -f2)
RC_ARCH=$(grep 'ARG ARCH=' ../Dockerfile | cut -d= -f2)

# Try to reuse the code from build_image_from_devel_cache.bash
eval "$(grep -m1 -A4 HOST_IP= build_image_from_devel_cache.bash)"
if [[ -z "$HOST_IP" ]]; then
    echo "Failed to guess docker ip"
    exit 1
fi >&2

if [[ ! -d cache ]]; then
    mkdir cache
fi

cd cache

# Get the actual manifest
if [[ ! -f MANIFEST.upstream ]]; then
    wget -O MANIFEST.upstream https://dls.rhodecode.com/linux/MANIFEST
fi
if ! ls RhodeCode-installer-* >&2 2>/dev/null ; then
    wget --content-disposition https://dls-eu.rhodecode.com/dls/NzA2MjdhN2E2ODYxNzY2NzZjNDA2NTc1NjI3MTcyNzA2MjcxNzIyZTcwNjI3YQ==/rhodecode-control/latest-linux-ce
fi
RC_INSTALLER=$(ls RhodeCode-installer* | head -1)
chmod 0755 "$RC_INSTALLER"
RC_INSTALLER_MD5=$(md5sum "$RC_INSTALLER" | awk '{print $1}')

VCS=$(grep "RhodeCodeVCSServer-${RC_VERSION}+${RC_ARCH}-linux.*" MANIFEST.upstream)
VCS_URL=$(awk '{print $2}' <<<"$VCS")
VCS_MD5=$(awk '{print $1}' <<<"$VCS")
VCS_FILENAME=$(basename "$VCS_URL")

RCC=$(grep "RhodeCodeCommunity-${RC_VERSION}+${RC_ARCH}-linux.*" MANIFEST.upstream)
RCC_URL=$(awk '{print $2}' <<<"$RCC")
RCC_MD5=$(awk '{print $1}' <<<"$RCC")
RCC_FILENAME=$(basename "$RCC_URL")

RC_CONTROL=$(grep "RhodeCodeControl-.*${RC_ARCH}-linux.*" MANIFEST.upstream)
RC_CONTROL_URL=$(awk '{print $2}' <<<"$RC_CONTROL")
RC_CONTROL_MD5=$(awk '{print $1}' <<<"$RC_CONTROL")
RC_CONTROL_FILENAME=$(basename "$RC_CONTROL_URL")

if [[ ! -f "$VCS_FILENAME" ]]; then
    wget "$VCS_URL"
fi
if [[ ! -f "$RCC_FILENAME" ]]; then
    wget "$RCC_URL"
fi
# if [[ ! -f "$RC_CONTROL_FILENAME" ]]; then
#     wget "$RC_CONTROL_URL"
# fi

# NOTE: The installer isn't included in the manifest, it must be downloaded
#       from RhodeCode's user area, I'm including it in the generated manifest
#       for easier debugging
SERVER="http://${HOST_IP}:8000"
# Generate a replacement MANIFEST
cat >MANIFEST <<-EOF
	$VCS_MD5 $SERVER/$VCS_FILENAME
	$RCC_MD5 $SERVER/$RCC_FILENAME
	$RC_CONTROL_MD5 $SERVER/$RC_CONTROL_FILENAME
	$RC_INSTALLER_MD5 $SERVER/$RC_INSTALLER
EOF

echo "Serving files on http://localhost:8000"
exec python3 -m http.server

exit 0
echo "Checking file hashes:"
md5sum -c <<<"$VCS_MD5  $VCS_FILENAME"
md5sum -c <<<"$RCC_MD5  $RCC_FILENAME"
# md5sum -c <<<"$RC_CONTROL_MD5  $RC_CONTROL_FILENAME"

