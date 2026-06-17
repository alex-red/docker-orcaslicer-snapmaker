# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-selkies:debiantrixie

# set version label
ARG BUILD_DATE
ARG VERSION
ARG SNAPMAKER_ORCA_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

# title
ENV TITLE="Snapmaker Orca" \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    NO_GAMEPAD=true \
    PIXELFLUX_WAYLAND=true

RUN \
  echo "**** add mozilla apt repo ****" && \
  install -d -m 0755 /etc/apt/keyrings && \
  curl -o \
    /etc/apt/keyrings/packages.mozilla.org.asc -L \
    https://packages.mozilla.org/apt/repo-signing-key.gpg && \
  echo \
    "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" > \
    /etc/apt/sources.list.d/mozilla.list && \
  printf \
    "Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n" > \
    /etc/apt/preferences.d/mozilla && \
  echo "**** install packages ****" && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive \
  apt-get install --no-install-recommends -y \
    firefox \
    gstreamer1.0-alsa \
    gstreamer1.0-gl \
    gstreamer1.0-gtk3 \
    gstreamer1.0-libav \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-pulseaudio \
    gstreamer1.0-qt5 \
    gstreamer1.0-tools \
    gstreamer1.0-x \
    libgstreamer-plugins-bad1.0 \
    libmspack0 \
    libwebkit2gtk-4.1-0 \
    libwx-perl \
    unzip && \
  echo "**** install snapmaker orca from appimage ****" && \
  SNAPMAKER_ORCA_API="https://api.github.com/repos/Snapmaker/OrcaSlicer" && \
  if [ -z "${SNAPMAKER_ORCA_VERSION:-}" ]; then \
    RELEASE_JSON=$(curl -fsSL "${SNAPMAKER_ORCA_API}/releases/latest"); \
  else \
    RELEASE_JSON=$(curl -fsSL "${SNAPMAKER_ORCA_API}/releases/tags/${SNAPMAKER_ORCA_VERSION}"); \
  fi && \
  DOWNLOAD_URL=$(printf "%s" "${RELEASE_JSON}" | awk -F'"' '/browser_download_url.*Snapmaker_Orca_Linux_ubuntu_2404_.*\.zip/{print $4;exit}') && \
  if [ -z "${DOWNLOAD_URL}" ]; then \
    echo "No Snapmaker Orca Ubuntu 24.04 Linux zip found for release ${SNAPMAKER_ORCA_VERSION:-latest}"; \
    exit 1; \
  fi && \
  cd /tmp && \
  curl -o \
    /tmp/snapmaker-orca.zip -fL \
    "${DOWNLOAD_URL}" && \
  unzip -q /tmp/snapmaker-orca.zip -d /tmp/snapmaker-orca && \
  APPIMAGE=$(find /tmp/snapmaker-orca -maxdepth 1 -type f -name "Snapmaker_Orca_Linux_AppImage_Ubuntu2404_*.AppImage" -print -quit) && \
  if [ -z "${APPIMAGE}" ]; then \
    echo "No Snapmaker Orca AppImage found inside downloaded zip"; \
    exit 1; \
  fi && \
  chmod +x "${APPIMAGE}" && \
  cd /tmp/snapmaker-orca && \
  "${APPIMAGE}" --appimage-extract && \
  if [ ! -x squashfs-root/AppRun ]; then \
    echo "Extracted Snapmaker Orca AppRun is missing or not executable"; \
    exit 1; \
  fi && \
  mv squashfs-root /opt/snapmaker-orca && \
  cp /opt/snapmaker-orca/Snapmaker_Orca.png /usr/share/selkies/www/icon.png && \
  localedef -i en_GB -f UTF-8 en_GB.UTF-8 && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** cleanup ****" && \
  apt-get autoclean && \
  rm -rf \
    /config/.cache \
    /config/.launchpadlib \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*

# add local files
COPY /root /

# ports and volumes
EXPOSE 3001
VOLUME /config
