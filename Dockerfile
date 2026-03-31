# ---------------------------------------------------------
# Ubuntu Development Environment
# ---------------------------------------------------------
FROM ubuntu:24.04

ARG GITHUB_USER
ENV GITHUB_USER="${GITHUB_USER}"

# ---------------------------------------------------------
# Install software globally
# ---------------------------------------------------------
# basic dev tools and the latest version of keepassxc
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common \
        curl git unzip build-essential cmake \
        python3 python3-pip sqlite3 tmux \
        libssl-dev zlib1g-dev libreadline-dev libffi-dev \
        fish php ghostscript texlive-latex-base imagemagick locales && \
    sed -i 's/^# *de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen de_DE.UTF-8 && \
    update-locale LANG=de_DE.UTF-8 LANGUAGE=de_DE:de LC_ALL=de_DE.UTF-8 && \
    add-apt-repository -y ppa:phoerious/keepassxc && \
    apt-get update && \
    apt-get install -y --no-install-recommends keepassxc && \
    ln -s /usr/bin/fdfind /usr/local/bin/fd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# set locale in environment
ENV LANG=de_DE.UTF-8 LANGUAGE=de_DE:de LC_ALL=de_DE.UTF-8

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
    chown -R "$GITHUB_USER:$GITHUB_USER" "/home/$GITHUB_USER" && \
    echo "$GITHUB_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$GITHUB_USER"

USER ${GITHUB_USER}
WORKDIR /home/${GITHUB_USER}/workspace

# Default command
CMD [ "/usr/local/bin/startup.sh" ]

