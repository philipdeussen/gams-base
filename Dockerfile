# Ubuntu 20.04 (focal)
ARG BASE_CONTAINER=ubuntu:focal-20210401@sha256:5403064f94b617f7975a19ba4d1a1299fd584397f6ee4393d0e16744ed11aab1
FROM $BASE_CONTAINER

# GAMS architecture, e.g. x64_64
ARG GAMS_ARCH="x64_64"
# GAMS version to use
ARG GAMS_VERSION="34.3.0"
ARG GAM_USER="gams"
ARG GAM_UID="1000"
ARG GAM_GID="100"

# Fix DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

ENV DEBIAN_FRONTEND noninteractive
ENV TZ UTC
RUN apt-get -q update \
    && apt-get install -yq --no-install-recommends \
    tzdata \
    wget \
    curl \
    software-properties-common \
    unzip \
    git \
    locales \
    nano \
    sudo \
    ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

COPY fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions

RUN mkdir -p /opt/gams &&\
    wget "https://d37drm4t2jghv5.cloudfront.net/distributions/${GAMS_VERSION}/linux/linux_x64_64_sfx.exe" -O /opt/gams/gams.exe &&\
    cd /opt/gams &&\
    chmod +x gams.exe; sync &&\
    ./gams.exe &&\
    rm -rf gams.exe &&\
    GAMS_PATH=$(dirname $(find / -name gams -type f -executable -print)) &&\
    echo "export PATH=\$PATH:$GAMS_PATH" >> ~/.bashrc &&\
    HOME=/home/${GAM_USER} &&\
    echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    useradd -l -m -s /bin/bash -N -u $GAM_UID $GAM_USER && \
    chown $NB_USER:$NB_GID $HOME && \
    chmod g+w /etc/passwd && \
    fix-permissions $HOME


USER ${GAM_UID}  

RUN mkdir "/home/${GAM_USER}/project" &&\
    fix-permissions "/home/${GAM_USER}"
  

WORKDIR $HOME