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

# Standard(ish) labels/annotations (org.opencontainers.*) <https://github.com/opencontainers/image-spec/blob/master/annotations.md>
LABEL maintainer="Toni Corvera <outlyer@gmail.com>" \
      org.opencontainers.image.name="Unofficial RhodeCode CE Dockerized" \
      org.opencontainers.image.description="RhodeCode Community Edition is an open\
source Source Code Management server with support for Git, Mercurial and Subversion\
(Subversion support is not -yet- enabled in this image, though)" \
      org.opencontainers.image.url="https://hub.docker.com/repository/docker/outlyernet/rhodecode-ce" \
      org.opencontainers.image.source="https://github.com/outlyer-net/docker-rhodecode-ce"
#LABEL org.opencontainers.image.licenses= # TODO
#LABEL org.opencontainers.image.version= # TODO

# Run before ENVs and ARGs, no need to pass all that environment (may help with caching)
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

RUN useradd --create-home --shell /bin/bash rhodecode \
        && sudo adduser rhodecode sudo \
        && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
        && locale-gen en_US.UTF-8 \
        && update-locale

# ARG RCC_VERSION=1.24.2
ARG RC_VERSION=4.22.0
ARG RC_ARCH=x86_64
# Allow overriding the manifest URL (for development purposes)
ARG RHODECODE_MANIFEST_URL="https://dls.rhodecode.com/linux/MANIFEST"
# TODO: Can this be downloaded more transparently?
# XXX: This URL is also used in the automation recipes <https://code.rhodecode.com/rhodecode-automation-ce/files/4ea5dcd54ba64245b0e1fea29b9ba29667d366b3/provisioning/ansible/provision_rhodecode_ce_vm.yaml>
ARG RHODECODE_INSTALLER_URL="https://dls-eu.rhodecode.com/dls/NzA2MjdhN2E2ODYxNzY2NzZjNDA2NTc1NjI3MTcyNzA2MjcxNzIyZTcwNjI3YQ==/rhodecode-control/latest-linux-ce"

# NOTE unattended installs only support sqlite (but can be reconfigured later)
ENV RHODECODE_USER=admin \
    RHODECODE_USER_PASS=secret \
    RHODECODE_USER_EMAIL=rhodecode-support@example.com \
    RHODECODE_DB=sqlite \
    RHODECODE_VCS_PORT=3690 \
    RHODECODE_HTTP_PORT=8080 \
    RHODECODE_HOST=0.0.0.0 \
    RHODECODE_REPO_DIR=/repos \
    RHODECODE_INSTALL_DIR=/rhodecode

COPY --chown=0:0 \
        container/healthcheck \
        container/entrypoint \
        container/reset_image \
        /
COPY --chown=0:0 build/setup-rhodecode.bash /tmp

USER rhodecode

RUN bash /tmp/setup-rhodecode.bash

# Make a backup of the initial data, so that it can be easily restored
RUN sudo mkdir /.rhodecode.dist \
        && sudo cp -rvpP ${RHODECODE_INSTALL_DIR}/ /.rhodecode.dist

# NOTE: Declared VOLUME's will be created at the point they're listed,
#       Must not create them early to avoid permission issues
VOLUME ${RHODECODE_REPO_DIR}
# These will contain RhodeCode installed files (which are much needed too)
#  By declaring them as volumes, if a Docker volume is mounted over them their contents
#  will be copied. However, that apparently doesn't apply to bind mounts.
VOLUME ${RHODECODE_INSTALL_DIR}

# Declared volumes are created as root, but must be writable by rhodecode
RUN chown rhodecode.rhodecode \
        ${RHODECODE_REPO_DIR} \
        ${RHODECODE_INSTALL_DIR}

HEALTHCHECK CMD [ "/healthcheck" ]

WORKDIR /home/rhodecode

EXPOSE 8080 3690

CMD [ "/entrypoint" ]
