FROM ubuntu:18.04
# Originally based on ubuntu:16.04.
# RhodeCode provides the relevant binaries so the actual OS
# version shouldn't make much of a difference.
#
# These are Ubuntu's current LTS:
#   Version   Supported until    Security support until
#   ----------------------------------------------------
#    16.04        2021-04               2024-04
#    18.04        2023-04               2028-04
#    20.04        2025-04               2030-04

LABEL maintainer="Toni Corvera <outlyer@gmail.com>"
# Standard(ish) labels/annotations <https://github.com/opencontainers/image-spec/blob/master/annotations.md>
LABEL org.opencontainers.image.name="Unofficial RhodeCode CE Dockerized"
LABEL org.opencontainers.image.description="RhodeCode Community Edition is an open\
source Source Code Management server with support for Git, Mercurial and Subversion\
(Subversion support is not -yet- enabled in this image, though)"
LABEL org.opencontainers.image.url="https://hub.docker.com/repository/docker/outlyernet/rhodecode-ce"
LABEL org.opencontainers.image.source="https://github.com/outlyer-net/docker-rhodecode-ce"
#LABEL org.opencontainers.image.licenses= # TODO
#LABEL org.opencontainers.image.version= # TODO


# ARG RCC_VERSION=1.24.2
ARG RC_VERSION=4.22.0
ARG ARCH=x86_64

ENV RHODECODE_USER=admin
ENV RHODECODE_USER_PASS=secret
ENV RHODECODE_USER_EMAIL=rhodecode-support@example.com
# NOTE unattended installs only support sqlite (but can be reconfigured later)
ENV RHODECODE_DB=sqlite
ENV RHODECODE_REPO_DIR=/home/rhodecode/repos
ENV RHODECODE_VCS_PORT=3690
ENV RHODECODE_HTTP_PORT=8080
ENV RHODECODE_HOST=0.0.0.0

RUN apt-get update \
        && DEBIAN_FRONTEND=noninteractive \
                apt-get -y install --no-install-recommends \
                    bzip2 \
                    ca-certificates \
                    locales \
                    python \
                    sudo \
                    supervisor \
                    tzdata \
                    wget

RUN useradd -ms /bin/bash rhodecode \
        && sudo adduser rhodecode sudo \
        && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
        && locale-gen en_US.UTF-8 \
        && update-locale

COPY container/healthcheck.sh /healthcheck

USER rhodecode

#VOLUME ${RHODECODE_REPO_DIR}
#VOLUME /home/rhodecode/.rccontrol/community-1
#VOLUME /home/rhodecode/.rccontrol/vcsserver-1

# Split into two scripts in an attempt to increase the chance of it being cached

# 1: Just the downloads
COPY build/prepare-downloads.bash /tmp
RUN env RC_VERSION=${RC_VERSION} ARCH=${ARCH} \
        bash /tmp/prepare-downloads.bash

# 2: Installation. Note reinstall is modified inside prepare-image.bash
COPY build/prepare-image.bash /tmp
COPY ./container/reinstall.sh /home/rhodecode/
RUN env RC_VERSION=${RC_VERSION} ARCH=${ARCH} \
        bash /tmp/prepare-image.bash

HEALTHCHECK CMD [ "/healthcheck" ]

WORKDIR /home/rhodecode
CMD ["supervisord", "-c", ".rccontrol/supervisor/supervisord.ini"]
