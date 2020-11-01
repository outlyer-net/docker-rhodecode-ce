FROM ubuntu:16.04

LABEL maintainer="Toni Corvera <outlyer@gmail.com>"

#ARG RCC_VERSION=1.24.2
ARG RC_VERSION=4.22.0
#ARG MANIFEST=https://dls.rhodecode.com/linux/MANIFEST
ARG ARCH=x86_64

# Commented-out since the old downloads aren't available anymore
# TODO: Consider alternatives

RUN apt-get update \
        && apt-get -y install \
                    bzip2 \
                    locales \
                    python \
                    sudo \
                    supervisor \
                    wget

RUN useradd -ms /bin/bash rhodecode \
        && sudo adduser rhodecode sudo \
        && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN locale-gen en_US.UTF-8 \
        && update-locale 

USER rhodecode

RUN mkdir -p /home/rhodecode/.rccontrol/cache

WORKDIR /home/rhodecode/.rccontrol/cache

#RUN wget https://dls.rhodecode.com/linux/RhodeCodeVCSServer-4.6.1+x86_64-linux_build20170213_1900.tar.bz2
#RUN wget https://dls.rhodecode.com/linux/RhodeCodeCommunity-4.6.1+x86_64-linux_build20170213_1900.tar.bz2

# https://docs.rhodecode.com/RhodeCode-Control/tasks/upgrade-rcc.html#offline-upgrading
# https://docs.rhodecode.com/RhodeCode-Control/tasks/offline-installer.html
# https://docs.rhodecode.com/RhodeCode-Control/tasks/install-cli.html#unattended-installation
RUN wget https://dls.rhodecode.com/linux/MANIFEST

# RUN grep -E 'RhodeCodeControl.*'${ARCH}'-linux' MANIFEST \
#             | awk '{print $2}' \
#             | xargs wget
# NOTE: Separated greps to avoid possible regexp issues with RC_VERSION's dots
RUN grep 'RhodeCodeVCSServer-'${RC_VERSION}'+'${ARCH}'-linux' MANIFEST \
            | awk '{print $2}' \
            | xargs echo wget \
        && grep 'RhodeCodeCommunity-'${RC_VERSION}'+'${ARCH}'-linux' MANIFEST \
            | awk '{print $2}' \
            | xargs echo wget

WORKDIR /home/rhodecode

# TODO: Can this be downloaded more transparently?
RUN wget --content-disposition https://dls-eu.rhodecode.com/dls/NzA2MjdhN2E2ODYxNzY2NzZjNDA2NTc1NjI3MTcyNzA2MjcxNzIyZTcwNjI3YQ==/rhodecode-control/latest-linux-ce
RUN chmod 755 ./RhodeCode-installer-*
RUN ./RhodeCode-installer-* --accept-license --create-install-directory
RUN .rccontrol-profile/bin/rccontrol self-init

ENV RHODECODE_USER=admin
ENV RHODECODE_USER_PASS=secret
ENV RHODECODE_USER_EMAIL=support@rhodecode.com
ENV RHODECODE_DB=sqlite
ENV RHODECODE_REPO_DIR=/home/rhodecode/repo
ENV RHODECODE_VCS_PORT=3690
ENV RHODECODE_HTTP_PORT=8080
ENV RHODECODE_HOST=0.0.0.0

RUN mkdir -p /home/rhodecode/repo

RUN .rccontrol-profile/bin/rccontrol install VCSServer --accept-license '{"host":"'"$RHODECODE_HOST"'", "port":'"$RHODECODE_VCS_PORT"'}' --version 4.6.1 --offline
RUN .rccontrol-profile/bin/rccontrol install --accept-license Community  '{"host":"'"$RHODECODE_HOST"'", "port":'"$RHODECODE_HTTP_PORT"', "username":"'"$RHODECODE_USER"'", "password":"'"$RHODECODE_USER_PASS"'", "email":"'"$RHODECODE_USER_EMAIL"'", "repo_dir":"'"$RHODECODE_REPO_DIR"'", "database": "'"$RHODECODE_DB"'"}' --version 4.6.1 --offline

RUN sed -i "s/start_at_boot = True/start_at_boot = False/g" ~/.rccontrol.ini
RUN sed -i "s/self_managed_supervisor = False/self_managed_supervisor = True/g" ~/.rccontrol.ini

RUN touch .rccontrol/supervisor/rhodecode_config_supervisord.ini
RUN echo "[supervisord]" >> .rccontrol/supervisor/rhodecode_config_supervisord.ini
RUN echo "nodaemon = true" >> .rccontrol/supervisor/rhodecode_config_supervisord.ini
RUN .rccontrol-profile/bin/rccontrol self-stop

COPY ./container/reinstall.sh /home/rhodecode/

CMD ["supervisord", "-c", ".rccontrol/supervisor/supervisord.ini"]
