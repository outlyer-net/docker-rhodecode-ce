#!/bin/bash

set -xe

RC_CONTROLDIR=~/.rccontrol
RC_CACHEDIR="${RC_CONTROLDIR}/cache"
RC_CONTROL=~/.rccontrol-profile/bin/rccontrol
REPOBASEDIR=~/repos

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

wget --content-disposition $WGET_OPTS "$RHODECODE_INSTALLER_URL"
chmod 0755 ./RhodeCode-installer-*

# Fail early if the required files and directories aren't found
test -f "${RC_CACHEDIR}/RhodeCodeCommunity"*
test -f "${RC_CACHEDIR}/RhodeCodeVCSServer"*
# Ensure the exported directories don't exist yet
test ! -d "$RC_CONTROLDIR/community-1"
test ! -d "$RC_CONTROLDIR/vcsserver-1"
test ! -d "${REPOBASEDIR}"

mkdir -p "${REPOBASEDIR}"

./RhodeCode-installer-* --accept-license --create-install-directory
"${RC_CONTROL}" self-init
# No point in removing while it's downloaded on a different layer
#rm ./RhodeCode-installer-*

# Important directories:
# - $RHODECODE_REPO_DIR (/home/rhodecode/repos)
#     Repositories root, one subdir per repository (all different types mixed)
# - ~/.rccontrol/community-1
#     RhodeCode CE configuration and logs. The sqlite database is located at ./rhodecode.db
# - ~/.rccontrol/vcsserver-1
#     RhodeCode's VCS Server configuration and logs
# NOTE ~/.rccontrol/ also includes cache/ and supervisor/, which I see no point in exporting

# NOTE RhodeCode-installer failed when installing to symlinked directories!
#      RhodeCode appears to run ok, if the directories are moved around afterwards

${RC_CONTROL} install VCSServer \
        --version ${RC_VERSION} \
        --accept-license \
        --offline \
        '{ "host": "'"$RHODECODE_HOST"'", '\
        '  "port":'"$RHODECODE_VCS_PORT"'}'
${RC_CONTROL} install Community \
        --version ${RC_VERSION} \
        --accept-license \
        --offline \
        '{"host":"'"$RHODECODE_HOST"'", '\
        ' "port":'"$RHODECODE_HTTP_PORT"', '\
        ' "username":"'"$RHODECODE_USER"'", '\
        ' "password":"'"$RHODECODE_USER_PASS"'", '\
        ' "email":"'"$RHODECODE_USER_EMAIL"'", '\
        ' "repo_dir":"'"$RHODECODE_REPO_DIR"'", '\
        ' "database": "'"$RHODECODE_DB"'"}'

sed -i \
    -e 's/start_at_boot = True/start_at_boot = False/g' \
    -e 's/self_managed_supervisor = False/self_managed_supervisor = True/g' \
    ~/.rccontrol.ini

echo -e '[supervisord]\nnodaemon = true' >> ${RC_CONTROLDIR}/supervisor/rhodecode_config_supervisord.ini
${RC_CONTROL} self-stop

echo "export PATH=\"\$PATH:~/.rccontrol-profile/bin\"" >> ~/.bashrc

# Remove unnecessary installation files
rm ~/RhodeCode-installer-*
rm "$RC_CACHEDIR"/*.bz2