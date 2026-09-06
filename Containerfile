FROM ubuntu:22.04

LABEL maintainer="ARM64 Desktop Environment (Termux-X11 Buildx Optimized)"
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:0
ENV USER=root

# ------------------------------------------------------------------------------
# STEP 1: Core Dependencies, X11, Desktop Environment, and Node.js 24
# ------------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    dbus \
    dbus-x11 \
    ca-certificates \
    wget \
    curl \
    gnupg \
    sudo \
    tar \
    xz-utils \
    unzip \
    bzip2 \
    jq \
    git \
    build-essential \
    cmake \
    pkg-config \
    wl-clipboard \
    zenity \
    pulseaudio-utils \
    alsa-utils \
    libgl1-mesa-dri \
    mesa-utils \
    xfce4 \
    xfce4-goodies \
    x11-xserver-utils \
    x11-utils \
    x11-apps \
    xwayland \
    software-properties-common \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update && apt-get install -y --no-install-recommends nodejs \
    && rm -f /etc/machine-id /var/lib/dbus/machine-id \
    && mkdir -p /var/lib/dbus \
    && dbus-uuidgen --ensure=/etc/machine-id \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------------
# STEP 2: Native Software Stack
# ------------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    wine \
    wine64 \
    kodi \
    retroarch \
    dolphin-emu \
    dosbox \
    scummvm \
    mame \
    mgba-qt \
    stella \
    vice \
    fs-uae \
    libreoffice \
    antimicrox \
    joystick \
    python3-gi \
    python3-yaml \
    python3-requests \
    python3-pil \
    python3-dbus \
    python3-certifi \
    gir1.2-gtk-3.0 \
    psmisc \
    cabextract \
    p7zip-full \
    shared-mime-info \
    || true && \
    rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------------
# STEP 3: Standalone Apps & AppImage Extractions (PRoot Safe)
# ------------------------------------------------------------------------------
# Download Kodi Addon Repo
RUN mkdir -p /root/Downloads && \
    IAGL_REPO_URL=$(curl -sL https://api.github.com/repos/zach-morris/repository.zachmorris/releases/latest | jq -r ".assets[]? | select(.name | endswith(\".zip\")) | .browser_download_url" | head -n 1) && \
    if [ -n "$IAGL_REPO_URL" ] && [ "$IAGL_REPO_URL" != "null" ]; then \
        wget -q -O /root/Downloads/repository.zachmorris.zip "$IAGL_REPO_URL"; \
    fi

# Extract DuckStation AppImage (if available for arm64)
RUN DUCK_ARM_URL=$(curl -sL -H "User-Agent: Mozilla/5.0" https://api.github.com/repos/stenzek/duckstation/releases/latest | jq -r ".assets[]? | select(.name | contains(\"arm64\") or contains(\"aarch64\")) | select(.name | endswith(\".AppImage\")) | .browser_download_url" | head -n 1) && \
    if [ -n "$DUCK_ARM_URL" ] && [ "$DUCK_ARM_URL" != "null" ]; then \
        wget -q -O /tmp/duckstation.AppImage "$DUCK_ARM_URL" && \
        chmod +x /tmp/duckstation.AppImage && \
        cd /tmp && ./duckstation.AppImage --appimage-extract && \
        mv /tmp/squashfs-root /opt/duckstation && \
        ln -sf /opt/duckstation/AppRun /usr/local/bin/duckstation && \
        rm -rf /tmp/duckstation.AppImage /tmp/squashfs-root; \
    fi

# Extract PPSSPP AppImage (if available for arm64)
RUN PPSSPP_ARM_URL=$(curl -sL -H "User-Agent: Mozilla/5.0" https://api.github.com/repos/hrydgard/ppsspp/releases/latest | jq -r ".assets[]? | select(.name | contains(\"arm64\") or contains(\"aarch64\")) | select(.name | endswith(\".AppImage\")) | .browser_download_url" | head -n 1) && \
    if [ -n "$PPSSPP_ARM_URL" ] && [ "$PPSSPP_ARM_URL" != "null" ]; then \
        wget -q -O /tmp/ppsspp.AppImage "$PPSSPP_ARM_URL" && \
        chmod +x /tmp/ppsspp.AppImage && \
        cd /tmp && ./ppsspp.AppImage --appimage-extract && \
        mv /tmp/squashfs-root /opt/ppsspp && \
        ln -sf /opt/ppsspp/AppRun /usr/local/bin/ppsspp && \
        rm -rf /tmp/ppsspp.AppImage /tmp/squashfs-root; \
    fi

# Download NetherSX2 Patch Builder Script
RUN mkdir -p /root/.local/share/emulators && \
    wget -q -O /root/.local/share/emulators/nethersx2-builder.sh "https://raw.githubusercontent.com/Trixarian/NetherSX2-patch/main/patch-apk.sh" || true && \
    chmod +x /root/.local/share/emulators/nethersx2-builder.sh 2>/dev/null || true

# Download & Install Lutris
RUN LUTRIS_DEB_URL=$(curl -sL -H "User-Agent: Mozilla/5.0" https://api.github.com/repos/lutris/lutris/releases | jq -r ".[].assets[]? | select(.name | endswith(\".deb\")) | .browser_download_url" | head -n 1) && \
    if [ -n "$LUTRIS_DEB_URL" ] && [ "$LUTRIS_DEB_URL" != "null" ]; then \
        wget -q -O /tmp/lutris.deb "$LUTRIS_DEB_URL" && \
        dpkg -i /tmp/lutris.deb || apt-get install -f -y && \
        rm -f /tmp/lutris.deb; \
    fi

# Final Cleanup
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/apt/archives/*

# ------------------------------------------------------------------------------
# STEP 4: Termux-X11 Startup Configuration
# ------------------------------------------------------------------------------
RUN printf '#!/bin/sh\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
export DISPLAY=${DISPLAY:-:0}\n\
export PULSE_SERVER=${PULSE_SERVER:-127.0.0.1:4713}\n\
rm -rf /tmp/.X0-lock /tmp/.X11-unix/X0\n\
exec dbus-launch --exit-with-session startxfce4\n' > /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
