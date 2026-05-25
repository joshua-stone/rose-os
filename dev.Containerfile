ARG IMAGE_NAME="${IMAGE_NAME:-rose-os-silverblue}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-rose-os-silverblue}"
ARG SOURCE_ORG="${SOURCE_ORG:-joshua-stone}"
ARG BASE_IMAGE="ghcr.io/${SOURCE_ORG}/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-44}"

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} as builder

ARG IMAGE_NAME="${IMAGE_NAME:-rose-os-silverblue}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-44}"

ARG IMAGE_NAME="${IMAGE_NAME:-rose-os-silverblue}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-44}"

COPY packages.sh /tmp/packages.sh
COPY dev-packages.json /tmp/packages.json
RUN sed -i "s@enabled=0@enabled=1@g" /etc/yum.repos.d/{fedora,fedora-updates}.repo
RUN /tmp/packages.sh
RUN sed -i "s@enabled=1@enabled=0@g" /etc/yum.repos.d/{fedora,fedora-updates}.repo
RUN ostree container commit && \
    mkdir -p /var/tmp && chmod -R 1777 /var/tmp
