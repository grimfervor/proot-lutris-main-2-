FROM ubuntu:22.04

LABEL maintainer="ARM64 Desktop Environment"
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV VNC_PORT=5901
ENV USER=root

# ------------------------------------------------------------------------------
# STEP 1: System Init, Core Dependencies, GUI, VNC, and Audio Stack
# ------------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    dbus \
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
    dbus-x11 \
    dbus-user-session \
    wl-clipboard \
    zenity \
    pulseaudio-utils \
    alsa-utils \
    libgl1-mesa-dri \
    mesa-utils \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    x11-xserver-utils \
    software-properties-common \
    && dbus-uuidgen > /etc/machine-id \
    && mkdir -p /var/lib/dbus \
    && ln -sf /etc/machine-id /var/lib/dbus/machine-id

# ------------------------------------------------------------------------------
# STEP 1.5: Node.js 24 Installation
# ------------------------------------------------------------------------------
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && apt-get install -y --no-install-recommends nodejs

# ------------------------------------------------------------------------------
# STEP 2: Repositories & Native ARM64 Software Stack
# ------------------------------------------------------------------------------
# Add FEX-Emu ARM64 PPA
RUN add-apt-repository -y ppa:fex-emu/fex || true

# Note: Removed pcsx2 as it lacks native arm64 deb packages in Ubuntu 22.04 repos
RUN apt-get update && apt-get install -y --no-install-recommends \
    fex-emu-arm64 \
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
    || true

# ------------------------------------------------------------------------------
# STEP 3: Standalone ARM64 Apps & Helper Scripts
# ------------------------------------------------------------------------------
# Download Zach Morris Repository (IAGL) for Kodi
RUN mkdir -p /root/Downloads && \
    IAGL_REPO_URL=$(curl -sL https://api.github.com/repos/zach-morris/repository.zachmorris/releases/latest | jq -r ".assets[]? | select(.name | endswith(\".zip\")) | .browser_download_url" | head -n 1) && \
    if [ -n "$IAGL_REPO_URL" ] && [ "$IAGL_REPO_URL" != "null" ]; then \
        wget -q -O /root/Downloads/repository.zachmorris.zip "$IAGL_REPO_URL"; \
    fi

# Download DuckStation ARM64 Release
RUN DUCK_ARM_URL=$(curl -sL -H "User-Agent: Mozilla/5.0" https://api.github.com/repos/stenzek/duckstation/releases/latest | jq -r ".assets[]? | select(.name | contains(\"arm64\") or contains(\"aarch64\")) | select(.name | endswith(\".AppImage\") or endswith(\".tar.gz\")) | .browser_download_url" | head -n 1) && \
    if [ -n "$DUCK_ARM_URL" ] && [ "$DUCK_ARM_URL" != "null" ]; then \
        wget -q -O /usr/local/bin/duckstation "$DUCK_ARM_URL" && chmod 755 /usr/local/bin/duckstation; \
    fi

# Download PPSSPP ARM64 Release
RUN PPSSPP_ARM_URL=$(curl -sL -H "User-Agent: Mozilla/5.0" https://api.github.com/repos/hrydgard/ppsspp/releases/latest | jq -r ".assets[]? | select(.name | contains(\"arm64\") or contains(\"aarch64\")) | select(.name | endswith(\".AppImage\") or endswith(\".tar.gz\")) | .browser_download_url" | head -n 1) && \
    if [ -n "$PPSSPP_ARM_URL" ] && [ "$PPSSPP_ARM_URL" != "null" ]; then \
        wget -q -O /usr/local/bin/ppsspp "$PPSSPP_ARM_URL" && chmod 755 /usr/local/bin/ppsspp; \
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

# Cleanup APT caches
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------------
# STEP 4: Configuration & Entrypoint
# ------------------------------------------------------------------------------
# Setup VNC Startup configuration
RUN mkdir -p /root/.vnc && \
    echo '#!/bin/sh\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nexec startxfce4' > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

EXPOSE 5901

# Entrypoint script to launch VNC Server in foreground mode
CMD ["sh", "-c", "vncserver :1 -geometry 1280x720 -depth 24 -fg"]
