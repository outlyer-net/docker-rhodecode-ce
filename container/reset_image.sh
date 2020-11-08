#!/bin/bash

RC_CONF='/home/rhodecode/.rccontrol/community-1'
VCS_CONF='/home/rhodecode/.rccontrol/vcsserver-1'
DIST_RC_CONF="$RC_CONF.dist"
DIST_VCS_CONF="$VCS_CONF.dist"

cat <<EOF
This script restores the installation data file that RhodeCode generated,
 in case you're mounting something over the corresponding directories.

 $RC_CONF
 and
 $VCS_CONF

If your configuration has somehow become corrupt this script will be of no use
 and it would be a better option to just recreate the container.

EOF

ensure_empty() {
    local target="$1"
    [[ -d "$1" ]] && ! ls "$target/"* >/dev/null 2>&1    
}

if ! ensure_empty "$RC_CONF" || ! ensure_empty "$VCS_CONF" ; then
    echo "*** ABORTING ***"
    echo "$RC_CONF and $VCS_CONF must exist and be empty."
    echo "****************"
    exit 1
fi >&2

if [[ ! -d "$DIST_RC_CONF" || ! -d "$DIST_VCS_CONF" ]]; then
    echo "*** ABORTING ***"
    echo "Backup of original installation data not found!"
    echo "****************"
    exit 2
fi

cp -rvpPT "$DIST_RC_CONF" "$RC_CONF"
cp -rvpPT "$DIST_VCS_CONF" "$VCS_CONF"
