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
    wget gnupg gnupg-agent dirmngr gosu \
    curl git unzip file cron locales \
    openssh-client sqlite3 \
    # --- build essentials (for mise/php/treesitter) ---
    build-essential \
    cmake \
    autoconf \
    bison \
    re2c \
    pkg-config \
    plocate \
    httpie \
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
    # --- timezone setup (Europe/Berlin with DST) ---
    ln -snf /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    echo "Europe/Berlin" > /etc/timezone && \
    # --- keepassxc ---
    add-apt-repository -y ppa:phoerious/keepassxc && \
    apt-get update && \
    apt-get install -y --no-install-recommends keepassxc && \
    # --- cleanup ---
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------
# Install Docker
# ---------------------------------------------------------
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends docker-ce-cli docker-buildx-plugin docker-compose-plugin && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------
# Install the system update job
# ---------------------------------------------------------
COPY jobs/sys-update.sh /usr/local/bin/sys-update.sh
RUN chown root:root /usr/local/bin/sys-update.sh && \
    chmod 755 /usr/local/bin/sys-update.sh
RUN echo "0 3 * * * root /usr/local/bin/sys-update.sh" > /etc/cron.d/update-cron && \
    chmod 0644 /etc/cron.d/update-cron

# ---------------------------------------------------------
# Install the user update job
# ---------------------------------------------------------
COPY jobs/mise-auto-update.sh /usr/local/bin/mise-auto-update.sh
RUN chown root:root /usr/local/bin/mise-auto-update.sh && \
    chmod 755 /usr/local/bin/mise-auto-update.sh
RUN test -n "$GITHUB_USER" || (echo "GITHUB_USER is empty!" && exit 1) && \
    echo "30 3 * * * ${GITHUB_USER} /usr/local/bin/mise-auto-update.sh" > /etc/cron.d/mise-update && \
    chmod 0644 /etc/cron.d/mise-update

# ---------------------------------------------------------
# Install Playwright (as root)
# ---------------------------------------------------------
RUN npx playwright install --with-deps chromium

# ---------------------------------------------------------
# Create a non-root user for development
# ---------------------------------------------------------
ENV HOME=/home/${GITHUB_USER}
ENV PATH=/home/${GITHUB_USER}/.local/bin:$PATH

RUN test -n "$GITHUB_USER" || (echo "GITHUB_USER is empty!" && exit 1) && \
    useradd -m -s /bin/bash "$GITHUB_USER" && \
    mkdir -p "/home/$GITHUB_USER/projects" && \
    chown -R "$GITHUB_USER:$GITHUB_USER" "/home/$GITHUB_USER" && \
    groupadd -f docker && \
    usermod -aG docker "$GITHUB_USER"

# Install startup script
COPY utils/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY utils/provision.sh /usr/local/bin/provision.sh
COPY utils/get_password.sh /usr/local/bin/get_password.sh
COPY utils/restore.sh /usr/local/bin/restore.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/provision.sh /usr/local/bin/get_password.sh /usr/local/bin/restore.sh

# Install dev scripts
COPY utils/prj /usr/local/bin/prj
RUN chmod +x /usr/local/bin/prj

HEALTHCHECK --interval=5m --timeout=3s --start-period=30s --retries=3 \
  CMD pgrep cron >/dev/null && test -f /home/${GITHUB_USER}/.local/bin/mise || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD [ "/usr/local/bin/provision.sh" ]
