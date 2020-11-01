#!/bin/bash

read -r -d '' CONF <<EOF
{
    "host": '$RHODECODE_HOST',
    "port": '$RHODECODE_HTTP_PORT',
    "username": '$RHODECODE_USER',
    "password": '$RHODECODE_USER_PASS',
    "email": '$RHODECODE_USER_EMAIL',
    "repo_dir": '$RHODECODE_REPO_DIR',
    "database": '$RHODECODE_DB'
}
EOF

~/.rccontrol-profile/bin/rccontrol uninstall community-1
~/.rccontrol-profile/bin/rccontrol install --accept-license Community \
    --version 4.6.1 \
    --offline \
    "$CONF"

