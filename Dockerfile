# ---------------------------------------------------------
# Ubuntu Development Environment
# ---------------------------------------------------------
FROM ubuntu:24.04

ARG GITHUB_USER
ENV GITHUB_USER="${GITHUB_USER}"

ENV LANG=de_DE.UTF-8
ENV LANGUAGE=de_DE:de
ENV LC_ALL=de_DE.UTF-8

# ---------------------------------------------------------
# Install software packages globally
# ---------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    # --- base tools and system ---
    software-properties-common \
    wget gnupg gnupg-agent dirmngr \
    curl git unzip locales \
    openssh-client sqlite3 \
    # --- build essentials (for mise/php/treesitter) ---
    build-essential \
    cmake \
    autoconf \
    bison \
    re2c \
    pkg-config \
    plocate \
    # --- PHP build dependencies (libraries) ---
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libonig-dev \
    libzip-dev \
    zlib1g-dev \
    libbz2-dev \
    # --- PHP graphics (additions for full gd support) ---
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    libavif-dev \
    libfreetype6-dev \
    libxpm-dev \
    libgd-dev \
    # --- PHP Databases ---
    libsqlite3-dev \
    libpq-dev \
    # --- PHP Misc, I18n & Formats ---
    libreadline-dev \
    libffi-dev \
    libyaml-dev \
    libicu-dev \
    libgmp-dev \
    libtidy-dev \
    libxslt1-dev \
    libgdbm-dev \
    libgdbm-compat-dev \
    libncurses5-dev \
    # --- applications ---
    fish \
    ghostscript \
    texlive-latex-base \
    imagemagick \
    kitty && \
    # --- locale setup ---
    sed -i 's/^# *de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen de_DE.UTF-8 && \
    update-locale LANG=de_DE.UTF-8 LANGUAGE=de_DE:de LC_ALL=de_DE.UTF-8 && \
    # --- keepassxc ---
    add-apt-repository -y ppa:phoerious/keepassxc && \
    apt-get update && \
    apt-get install -y --no-install-recommends keepassxc && \
    # --- cleanup ---
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Neovim (v0.11.7)
RUN curl -LO https://github.com/neovim/neovim/releases/download/v0.11.5/nvim-linux-x86_64.tar.gz \
    && tar xzf nvim-linux-x86_64.tar.gz \
    && mv nvim-linux-x86_64 /opt/nvim \
    && ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim \
    && rm nvim-linux-x86_64.tar.gz

# Install startup script
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

# ---------------------------------------------------------
# Create a non-root user for development
# ---------------------------------------------------------
ARG GITHUB_USER

ENV GITHUB_USER=${GITHUB_USER}
ENV HOME=/home/${GITHUB_USER}

RUN test -n "$GITHUB_USER" || (echo "GITHUB_USER is empty!" && exit 1) && \
    useradd -m -s /bin/bash "$GITHUB_USER" && \
    mkdir -p "/home/$GITHUB_USER/workspace" && \
    chown -R "$GITHUB_USER:$GITHUB_USER" "/home/$GITHUB_USER"

USER ${GITHUB_USER}
WORKDIR /home/${GITHUB_USER}/workspace
ENV PATH="${HOME}/.local/bin:${PATH}"

# Default command
CMD [ "/usr/local/bin/startup.sh" ]
