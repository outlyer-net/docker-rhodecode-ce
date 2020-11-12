#!/bin/bash

set -xe

test $UID -eq 0

RC_CONTROLDIR=~/.rccontrol
RC_CACHEDIR="${RHODECODE_INSTALL_DIR}/cache"
RC_CONTROL=~/.rccontrol-profile/bin/rccontrol

mkdir "${RHODECODE_INSTALL_DIR}" "${RC_CACHEDIR}"
cd "${RC_CACHEDIR}"

# Avoid producing garbage (specially useful to ease reading Docker Hub's build logs) 
WGET_OPTS='--progress=dot:giga'

# https://docs.rhodecode.com/RhodeCode-Control/tasks/upgrade-rcc.html#offline-upgrading
# https://docs.rhodecode.com/RhodeCode-Control/tasks/offline-installer.html
# https://docs.rhodecode.com/RhodeCode-Control/tasks/install-cli.html#unattended-installation
wget $WGET_OPTS $RHODECODE_MANIFEST_URL

# RUN grep -E 'RhodeCodeControl.*'${RC_ARCH}'-linux' MANIFEST \
#             | awk '{print $2}' \
#             | xargs wget
# NOTE: Separated greps to avoid possible regexp issues with RC_VERSION's dots
grep 'RhodeCodeVCSServer-'${RC_VERSION}'+'${RC_ARCH}'-linux' MANIFEST \
    | awk '{print $2}' \
    | xargs wget $WGET_OPTS
grep 'RhodeCodeCommunity-'${RC_VERSION}'+'${RC_ARCH}'-linux' MANIFEST \
    | awk '{print $2}' \
    | xargs wget $WGET_OPTS

wget --content-disposition $WGET_OPTS "$RHODECODE_INSTALLER_URL"
chmod 0755 ./RhodeCode-installer-*

# Fail early if the required files and directories aren't found
test -f "${RC_CACHEDIR}/RhodeCodeCommunity"*
test -f "${RC_CACHEDIR}/RhodeCodeVCSServer"*
# Ensure the exported directories don't exist yet
test ! -d "${RHODECODE_INSTALL_DIR}/community-1"
test ! -d "${RHODECODE_INSTALL_DIR}/vcsserver-1"
test ! -d "${RHODECODE_REPO_DIR}"

mkdir -p "${RHODECODE_REPO_DIR}"

# RhodeCode-installer creates
# - $HOME/.rccontrol/
#     - $HOME/.rccontrol/cache/MANIFEST
#     - $HOME/.rccontrol/supervisor/supervisord.* (also created by rccontrol install)
# - $HOME/.rccontrol-profile (symlink to /opt/rhodecode/store...)
# - $HOME/.profile: adds .rccontrol-profile/bin to path
# But it doesn't appear to allow setting target directory manually and
#  will use $HOME, override it temporarily...
env HOME="${RHODECODE_INSTALL_DIR}" \
    ./RhodeCode-installer-* --as-root --accept-license --create-install-directory
# ... And move files around manually
mv -v "${RHODECODE_INSTALL_DIR}"/.rccontrol/cache/MANIFEST "${RHODECODE_INSTALL_DIR}"/cache/
mv -v "${RHODECODE_INSTALL_DIR}"/.rccontrol/supervisor "${RHODECODE_INSTALL_DIR}"/supervisor
mv -v "${RHODECODE_INSTALL_DIR}"/.rccontrol-profile "${HOME}"/
rmdir -v "${RHODECODE_INSTALL_DIR}"/.rccontrol{/cache,/}
mv -v "${RHODECODE_INSTALL_DIR}"/.profile /etc/profile.d/99-rhodecode-path.sh

"${RC_CONTROL}" --install-dir="${RHODECODE_INSTALL_DIR}" self-init

# Important directories:
# - $RHODECODE_REPO_DIR (/repos)
#     Repositories root, one subdir per repository (all different types mixed)
# - /rhodecode/community-1 (by default ~/.rccontrol/community-1)
#     RhodeCode CE configuration and logs. The sqlite database is located at ./rhodecode.db
# - /rhodecode/vcsserver-1 (by default ~/.rccontrol/vcsserver-1)
#     RhodeCode's VCS Server configuration and logs
# NOTE ~/.rccontrol/ also includes cache/ and supervisor/, which I see no point in exporting

# NOTE RhodeCode-installer failed when installing to symlinked directories!
#      RhodeCode appears to run ok, if the directories are moved around afterwards

${RC_CONTROL} install VCSServer \
        --version ${RC_VERSION} \
        --accept-license \
        --offline \
        --install-dir "${RHODECODE_INSTALL_DIR}" \
        '{ "host": "'"$RHODECODE_HOST"'", '\
        '  "port":'"$RHODECODE_VCS_PORT"'}'
${RC_CONTROL} install Community \
        --version ${RC_VERSION} \
        --accept-license \
        --offline \
        --install-dir "${RHODECODE_INSTALL_DIR}" \
        '{"host":"'"$RHODECODE_HOST"'", '\
        ' "port":'"$RHODECODE_HTTP_PORT"', '\
        ' "username":"'"$RHODECODE_USER"'", '\
        ' "password":"'"$RHODECODE_USER_PASS"'", '\
        ' "email":"'"$RHODECODE_USER_EMAIL"'", '\
        ' "repo_dir":"'"$RHODECODE_REPO_DIR"'", '\
        ' "database": "'"$RHODECODE_DB"'"}'

# supervisord.ini is partially set up, but the log and pid file paths must be rewritten
sed -i -e "s!$RHODECODE_INSTALL_DIR/.rccontrol/supervisor/supervisord.!$RHODECODE_INSTALL_DIR/supervisor/supervisord.!" \
    "${RHODECODE_INSTALL_DIR}"/supervisor/supervisord.ini

# TODO: should this be in ~ or in $RHODECODE_INSTALL_DIR ?
sed -i \
    -e 's/start_at_boot = True/start_at_boot = False/g' \
    -e 's/self_managed_supervisor = False/self_managed_supervisor = True/g' \
    ~/.rccontrol.ini

echo -e '[supervisord]\nnodaemon = true' >> ${RHODECODE_INSTALL_DIR}/supervisor/rhodecode_config_supervisord.ini
${RC_CONTROL} self-stop --install-dir "${RHODECODE_INSTALL_DIR}"

#echo "export PATH=\"\$PATH:~/.rccontrol-profile/bin\"" >> ~/.bashrc

# TODO: can rccontrol pick up the install dir otherwise?
cat >/usr/local/bin/rccontrol <<EOF
#!/bin/sh
exec "$HOME/.rccontrol-profile/bin/rccontrol" \
    --install-dir="$RHODECODE_INSTALL_DIR" \
    "\$@"
EOF
chmod 0755 /usr/local/bin/rccontrol

# Remove unnecessary installation files
rm "${RC_CACHEDIR}"/RhodeCode-installer-*
rm "${RC_CACHEDIR}"/*.bz2

# Symlink the scm binaries/wrappers used by RhodeCode convenience
find /opt/rhodecode/store/*vcsserver* \
    \( \
        -name 'svn' \
        -or \
        -name 'git' \
        -or \
        -name 'hg' \
    \) \
    -exec ln -s '{}' /usr/local/bin/ \;
