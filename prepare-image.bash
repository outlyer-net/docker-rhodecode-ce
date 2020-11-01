#!/bin/bash

set -xe

RC_CONTROLDIR=~/.rccontrol
RC_CACHEDIR="${RC_CONTROLDIR}/cache"
RC_CONTROL=~/.rccontrol-profile/bin/rccontrol
REPOBASEDIR=~/repo

# Fail early if the required files and directories aren't found
test -f ~/reinstall.sh
test -f "${RC_CACHEDIR}/RhodeCodeCommunity"*
test -f "${RC_CACHEDIR}/RhodeCodeVCSServer"*
test -x ~/RhodeCode-installer-*

mkdir -p "${REPOBASEDIR}"

cd ~
./RhodeCode-installer-* --accept-license --create-install-directory
"${RC_CONTROL}" self-init
# No point in removing while it's downloaded on a different layer
#rm ./RhodeCode-installer-*

# Important directories:
# - $RHODECODE_REPO_DIR (/home/rhodecode/repo)
#     Repositories root, one subdir per repository (all different types mixed)
# - ~/.rccontrol/community-1
#     RhodeCode CE configuration and logs. The sqlite database is located at ./rhodecode.db
# - ~/.rccontrol/vcsserver-1
#     RhodeCode's VCS Server configuration and logs
# NOTE ~/.rccontrol/ also includes cache/ and supervisor/, which I see no point in exporting

# NOTE RhodeCode-installer won't install to symlinked directories!
#      RhodeCode appears to run ok, if the directories are moved around  

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

#touch .rccontrol/supervisor/rhodecode_config_supervisord.ini
echo -e '[supervisord]\nnodaemon = true' >> ${RC_CONTROLDIR}/supervisor/rhodecode_config_supervisord.ini
${RC_CONTROL} self-stop

sed -i 's/^RC_VERSION=.*/RC_VERSION='${RC_VERSION}'/' ~/reinstall.sh
