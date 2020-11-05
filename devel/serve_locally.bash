#!/bin/bash

# Avoid hammering RhodeCode's servers unnecessarily and waiting for downloads
#  by caching them and serving locally
# Files are only downloaded when this script is invoked if they don't already
#  exist, no further sanity checks are made

cd "$(dirname "$0")"

RC_VERSION=$(grep 'ARG RC_VERSION=' ../Dockerfile | cut -d= -f2)
RC_ARCH=$(grep 'ARG ARCH=' ../Dockerfile | cut -d= -f2)

if [[ ! -d cache ]]; then
    mkdir cache
fi

cd cache

# Get the actual manifest
if [[ ! -f MANIFEST.upstream ]]; then
    wget -O MANIFEST.upstream https://dls.rhodecode.com/linux/MANIFEST
fi

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

# Generate a replacement MANIFEST
cat >MANIFEST <<-EOF
	$VCS_MD5 $VCS_FILENAME
	$RCC_MD5 $RCC_FILENAME
	$RC_CONTROL_MD5 $RC_CONTROL_FILENAME
EOF

echo "Serving files on http://localhost:8000"
exec python3 -m http.server

exit 0
echo "Checking file hashes:"
md5sum -c <<<"$VCS_MD5  $VCS_FILENAME"
md5sum -c <<<"$RCC_MD5  $RCC_FILENAME"
# md5sum -c <<<"$RC_CONTROL_MD5  $RC_CONTROL_FILENAME"

