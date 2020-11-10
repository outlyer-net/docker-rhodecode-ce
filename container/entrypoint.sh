#!/bin/sh

# Fix ownership on each invocation
sudo chown -R `id -u`.`id -g` \
    ${RHODECODE_INSTALL_DIR}/community-1 \
    ${RHODECODE_INSTALL_DIR}/vcsserver-1 \
    ${RHODECODE_REPO_DIR}

exec supervisord -c ${RHODECODE_INSTALL_DIR}/supervisor/supervisord.ini
