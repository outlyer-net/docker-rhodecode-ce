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

# Run before ENVs and ARGs, no need to pass all that environment (may help with caching)
# NOTE: sudo is required by RhodeCode-installer even when installed as root
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
                    wget \
        && rm -rf /var/lib/apt/lists/* 

RUN locale-gen en_US.UTF-8 \
        && update-locale

# ARG RCC_VERSION=1.24.2
ARG RC_VERSION=4.22.0
ARG RC_ARCH=x86_64
# Allow overriding the manifest URL (for development purposes)
ARG RHODECODE_MANIFEST_URL="https://dls.rhodecode.com/linux/MANIFEST"
# TODO: Can this be downloaded more transparently?
# XXX: This URL is also used in the automation recipes <https://code.rhodecode.com/rhodecode-automation-ce/files/4ea5dcd54ba64245b0e1fea29b9ba29667d366b3/provisioning/ansible/provision_rhodecode_ce_vm.yaml>
ARG RHODECODE_INSTALLER_URL="https://dls-eu.rhodecode.com/dls/NzA2MjdhN2E2ODYxNzY2NzZjNDA2NTc1NjI3MTcyNzA2MjcxNzIyZTcwNjI3YQ==/rhodecode-control/latest-linux-ce"

# Standard(ish) labels/annotations (org.opencontainers.*) <https://github.com/opencontainers/image-spec/blob/master/annotations.md>
LABEL maintainer="Toni Corvera <outlyer@gmail.com>" \
      org.opencontainers.image.name="Unofficial RhodeCode CE Dockerized" \
      org.opencontainers.image.description="RhodeCode Community Edition is an open\
source Source Code Management server with support for Git, Mercurial and Subversion\
(Subversion support is not -yet- enabled in this image, though)" \
      org.opencontainers.image.url="https://hub.docker.com/repository/docker/outlyernet/rhodecode-ce" \
      org.opencontainers.image.source="https://github.com/outlyer-net/docker-rhodecode-ce" \
      org.opencontainers.image.version=${RC_VERSION}
#LABEL org.opencontainers.image.licenses= # TODO

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

COPY --chown=0:0 build/setup-rhodecode.bash /tmp
RUN bash /tmp/setup-rhodecode.bash

# Make a backup of the initial data, so that it can be easily restored
RUN cp -rvpPT ${RHODECODE_INSTALL_DIR}/ /.rhodecode.dist

COPY --chown=0:0 container/* /

# NOTE: Declared VOLUMEs will be created at the point they're listed
# RHODECODE_INSTALL_DIR will contain RhodeCode installed files (which are necessary)
#  By declaring it as a volume, if a Docker volume is mounted over it its
#  contents will be copied. However, that doesn't apply to bind mounts
#  (/entrypoint will copy files from /.rhodecode.dist to mimic that behaviour).
VOLUME ${RHODECODE_REPO_DIR} ${RHODECODE_INSTALL_DIR}

EXPOSE 8080 3690

HEALTHCHECK CMD [ "/healthcheck" ]
ENTRYPOINT [ "/entrypoint" ]
