#!/bin/bash

set -xe

RC_CONTROLDIR=~/.rccontrol
RC_CACHEDIR="${RC_CONTROLDIR}/cache"

sudo chown -R rhodecode.rhodecode ~
mkdir -p "${RC_CACHEDIR}"
cd "${RC_CACHEDIR}"

# Avoid producing garbage (specially useful to ease reading Docker Hub's build logs) 
WGET_OPTS='--progress=dot:giga'

# https://docs.rhodecode.com/RhodeCode-Control/tasks/upgrade-rcc.html#offline-upgrading
# https://docs.rhodecode.com/RhodeCode-Control/tasks/offline-installer.html
# https://docs.rhodecode.com/RhodeCode-Control/tasks/install-cli.html#unattended-installation
wget $WGET_OPTS $RHODECODE_MANIFEST_URL

# RUN grep -E 'RhodeCodeControl.*'${ARCH}'-linux' MANIFEST \
#             | awk '{print $2}' \
#             | xargs wget
# NOTE: Separated greps to avoid possible regexp issues with RC_VERSION's dots
grep 'RhodeCodeVCSServer-'${RC_VERSION}'+'${ARCH}'-linux' MANIFEST \
    | awk '{print $2}' \
    | xargs wget $WGET_OPTS
grep 'RhodeCodeCommunity-'${RC_VERSION}'+'${ARCH}'-linux' MANIFEST \
    | awk '{print $2}' \
    | xargs wget $WGET_OPTS

cd ~

# TODO: Can this be downloaded more transparently?
# TODO: Can the installer be removed safely afterwards?
# XXX: This URL is also used in the automation recipes <https://code.rhodecode.com/rhodecode-automation-ce/files/4ea5dcd54ba64245b0e1fea29b9ba29667d366b3/provisioning/ansible/provision_rhodecode_ce_vm.yaml>
wget --content-disposition https://dls-eu.rhodecode.com/dls/NzA2MjdhN2E2ODYxNzY2NzZjNDA2NTc1NjI3MTcyNzA2MjcxNzIyZTcwNjI3YQ==/rhodecode-control/latest-linux-ce
chmod 0755 ./RhodeCode-installer-*
