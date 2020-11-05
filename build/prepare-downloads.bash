#!/bin/bash

set -xe

RC_CONTROLDIR=~/.rccontrol
RC_CACHEDIR="${RC_CONTROLDIR}/cache"

mkdir -p "${RC_CACHEDIR}"
cd "${RC_CACHEDIR}"

# https://docs.rhodecode.com/RhodeCode-Control/tasks/upgrade-rcc.html#offline-upgrading
# https://docs.rhodecode.com/RhodeCode-Control/tasks/offline-installer.html
# https://docs.rhodecode.com/RhodeCode-Control/tasks/install-cli.html#unattended-installation
wget $RHODECODE_MANIFEST_URL

# RUN grep -E 'RhodeCodeControl.*'${ARCH}'-linux' MANIFEST \
#             | awk '{print $2}' \
#             | xargs wget
# NOTE: Separated greps to avoid possible regexp issues with RC_VERSION's dots
grep 'RhodeCodeVCSServer-'${RC_VERSION}'+'${ARCH}'-linux' MANIFEST \
    | awk '{print $2}' \
    | xargs wget
grep 'RhodeCodeCommunity-'${RC_VERSION}'+'${ARCH}'-linux' MANIFEST \
    | awk '{print $2}' \
    | xargs wget

cd ~

# TODO: Can this be downloaded more transparently?
# TODO: Can the installer be removed safely afterwards?
wget --content-disposition https://dls-eu.rhodecode.com/dls/NzA2MjdhN2E2ODYxNzY2NzZjNDA2NTc1NjI3MTcyNzA2MjcxNzIyZTcwNjI3YQ==/rhodecode-control/latest-linux-ce
chmod 0755 ./RhodeCode-installer-*
