### ----------------------------
###  Temporary stage, see below
### ----------------------------
#
# Running as root isn't allowed in default builds (neither ubuntu nor httpd images),
#  recompiling appears to be the only option
#  <https://stackoverflow.com/questions/37099831/>
#

FROM ubuntu:18.04 AS buildstage
# Set to match the FROM above
ARG UBUNTU_SUITE=bionic

# Downloaded sources will be placed directly at the root, the generated deb packages will be too
# Note subversion (libapache2-mod-svn) is in universe, but there's no need to
#  rebuild the svn module
ENV DEBIAN_FRONTEND='noninteractive'
RUN grep '^# deb-src' /etc/apt/sources.list \
        | sed -r \
            -e "/${UBUNTU_SUITE}.*(universe|multiverse|partner)/d" \
            -e 's/^# //' \
        | tee /etc/apt/sources.list.d/deb-src.list \
        \
        && apt-get update \
        && apt-get install -y --no-install-recommends debhelper dpkg-dev \
        && apt-get build-dep -y --no-install-recommends apache2 \
        && apt-get source apache2

# TODO: Consider setting an epoch in the deb
ENV DEB_CFLAGS_APPEND="-DBIG_SECURITY_HOLE"
RUN cd apache2*/ && dpkg-buildflags --get CFLAGS && dpkg-buildpackage -b

### ------------------
###  The actual image
### ------------------
#
# Reference docs from RhodeCode
#  <https://docs.rhodecode.com/RhodeCode-Enterprise/admin/svn-http.html>
#

FROM ubuntu:18.04 AS mainstage

# Packages installed when apt-installing apache2 and libapache2-mod-svn
COPY --from=buildstage \
    /apache2_*.deb \
    /apache2-bin*.deb \
    /apache2-data*.deb \
    /apache2-utils*.deb \
    /tmp/

#     && export DEB_CFLAGS_SET="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -DBIG_SECURITY_HOLE" \
RUN apt-get update \
        && dpkg -i /tmp/*.deb || apt-get install -f -y --no-install-recommends \
        && DEBIAN_FRONTEND=noninteractive \
            apt-get install -y --no-install-recommends libapache2-mod-svn

# XXX: Corresponding ENV variables don't appear to be parsed
RUN sed -i \
        -e 's/APACHE_RUN_USER=.*/APACHE_RUN_USER=root/' \
        -e 's/APACHE_RUN_GROUP=.*/APACHE_RUN_GROUP=root/' \
        /etc/apache2/envvars
# ENV APACHE_RUN_USER=root \
#     APACHE_RUN_GROUP=root

# - Text configuration
# - Ensure BIG_SECURITY_HOLE was used at compile time
# - Ensure the dav_svn module is enabled
RUN apache2ctl configtest \
        && apache2ctl -V | grep -q BIG_SECURITY_HOLE \
        && a2query -m dav_svn

EXPOSE 80

CMD apache2ctl -D FOREGROUND
