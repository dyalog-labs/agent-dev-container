# trixie (Debian 13) for glibc >= 2.38, required by Dyalog 21
FROM node:26-trixie

ARG TZ
ENV TZ="$TZ"

# Install basic development tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    less \
    git \
    procps \
    sudo \
    locales \
    ca-certificates \
    fzf \
    zsh \
    man-db \
    unzip \
    gnupg2 \
    gh \
    jq \
    nano \
    vim \
    python3 \
    python3-pip \
    python3-venv \
    pipx \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Generate UTF-8 locale so shells don't warn when LC_ALL is inherited.
RUN sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LANGUAGE=en_US:en


# --- Dyalog APL ---
# Installs the newest build listed in Dyalog's metafile for this architecture.
# Set DYALOG_APL_VERSION (e.g. 20.0) to pin a release; the newest build of that
# release is used. ADD re-fetches the metafile on every build and invalidates
# the cache for this layer whenever its contents change (i.e. a new build or
# release is published).
ARG DYALOG_APL_VERSION=
ADD --chmod=644 https://www.dyalog.com/uploads/php/download.dyalog.com/download.php?file=docker.metafile /tmp/dyalog.metafile
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
    arm64) dyalog_arch="aarch64" ;; \
    amd64) dyalog_arch="x86_64" ;; \
    *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    url="$(awk -F'\t' -v v="$DYALOG_APL_VERSION" -v a="$dyalog_arch" \
        '(v == "" || $1 == v) && $2 == "deb" && $3 ~ ("_unicode\\." a "\\.deb$") { print $3 }' \
        /tmp/dyalog.metafile | sort -V | tail -n 1)"; \
    if [ -z "$url" ]; then \
        echo "No Dyalog ${DYALOG_APL_VERSION:-(any version)} .deb for ${dyalog_arch} in metafile:" >&2; \
        cat /tmp/dyalog.metafile >&2; \
        exit 1; \
    fi; \
    echo "Installing Dyalog from $url"; \
    wget -O /tmp/dyalog.deb "$url"; \
    dpkg -i /tmp/dyalog.deb || (apt-get update && apt-get install -y -f --no-install-recommends); \
    rm -f /tmp/dyalog.deb /tmp/dyalog.metafile; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# --- Go ---
# Installs the newest stable Go release listed by go.dev. Set GO_VERSION to pin
# a release line (e.g. 1.26, newest patch of it) or an exact version (e.g.
# 1.26.3). ADD re-fetches the release list on every build and invalidates the
# cache for this layer whenever a new release is published.
ARG GO_VERSION=
ADD --chmod=644 https://go.dev/dl/?mode=json&include=all /tmp/go-releases.json
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
    arm64|amd64) goarch="$arch" ;; \
    *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    release="$(jq -r --arg v "$GO_VERSION" --arg a "$goarch" ' \
        .[] | select(.stable) \
        | select($v == "" or .version == "go" + $v or (.version | startswith("go" + $v + "."))) \
        | .files[] | select(.os == "linux" and .kind == "archive" and .arch == $a) \
        | "\(.version) \(.filename) \(.sha256)"' \
        /tmp/go-releases.json | sort -V | tail -n 1)"; \
    if [ -z "$release" ]; then \
        echo "No stable Go ${GO_VERSION:-(any version)} release for linux-${goarch} on go.dev" >&2; \
        exit 1; \
    fi; \
    set -- $release; \
    echo "Installing $1 from https://go.dev/dl/$2"; \
    wget -O /tmp/go.tar.gz "https://go.dev/dl/$2"; \
    echo "$3  /tmp/go.tar.gz" | sha256sum -c -; \
    tar -C /usr/local -xzf /tmp/go.tar.gz; \
    rm -f /tmp/go.tar.gz /tmp/go-releases.json

ENV PATH=$PATH:/usr/local/go/bin

# Install .NET SDK
RUN wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh \
    && chmod +x dotnet-install.sh \
    && ./dotnet-install.sh --channel 10.0 --install-dir /usr/local/dotnet \
    && rm dotnet-install.sh

ENV DOTNET_ROOT=/usr/local/dotnet
ENV PATH=$PATH:/usr/local/dotnet

# Ensure default node user has access to npm global install path
RUN mkdir -p /usr/local/share/npm-global \
    && chown -R node:node /usr/local/share/npm-global

ARG USERNAME=node

# Persist shell history
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && mkdir /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R "$USERNAME":"$USERNAME" /commandhistory

ENV DEVCONTAINER=true

# Create workspace and config directories and set permissions
RUN mkdir -p /workspace /home/node/.claude \
    && chown -R node:node /workspace /home/node/.claude

WORKDIR /workspace

ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
    wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
    dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
    rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

# Build docsearch and bundle-docs (Dyalog documentation search)
RUN git clone --depth=1 https://github.com/xpqz/bundle-docs.git /tmp/bundle-docs \
    && cd /tmp/bundle-docs \
    && CGO_ENABLED=1 go build -tags "fts5" -o /usr/local/bin/bundle-docs . \
    && CGO_ENABLED=1 go build -tags "fts5" -o /usr/local/bin/docsearch ./cmd/docsearch \
    && rm -rf /tmp/bundle-docs /root/go

# Download pre-built Dyalog documentation database
RUN mkdir -p /home/node/.bundle-docs \
    && wget -O /home/node/.bundle-docs/dyalog-docs.db \
       https://github.com/xpqz/bundle-docs/releases/download/v1.0.0/dyalog-docs.db \
    && chown -R node:node /home/node/.bundle-docs

# Set up non-root user
USER node

ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV GOPATH=/home/node/go
ENV PATH=$PATH:/usr/local/share/npm-global/bin:/home/node/.local/bin:/home/node/go/bin:/home/node/.dotnet/tools
ENV SHELL=/bin/zsh
ENV EDITOR=nano
ENV VISUAL=nano

# Install LSP servers for each supported toolchain.
# csharp-ls is pinned because the publisher has occasionally pushed broken
# .nupkg files (DotnetToolSettings.xml missing) that take down the whole
# image build. The `|| echo` swallows future failures so an upstream break
# of csharp-ls does not block the rest of the build; C# LSP support is
# optional, the kit only enables typescript-lsp and pyright by
# default.
RUN go install golang.org/x/tools/gopls@latest
RUN dotnet tool install --global csharp-ls --version 0.28.0 \
    || echo "WARNING: csharp-ls install failed; C# LSP will be unavailable in this image"
RUN npm install -g typescript typescript-language-server
RUN pipx install python-lsp-server

ARG ZSH_IN_DOCKER_VERSION=1.2.0
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
    -p git \
    -p fzf \
    -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
    -a "source /usr/share/doc/fzf/examples/completion.zsh" \
    -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    -x

# Install Claude Code (native install - auto-updates at runtime).
# ADD fetches the current "latest" version string on every build; when a new
# release ships its contents change, invalidating the cache so the RUN below
# installs the new release instead of reusing a stale cached layer.
ADD --chmod=644 https://downloads.claude.ai/claude-code-releases/latest /tmp/claude-code-latest-version
RUN curl -fsSL https://claude.ai/install.sh -o /tmp/claude-install.sh \
    && bash /tmp/claude-install.sh latest \
    && rm -f /tmp/claude-install.sh \
    && command -v claude \
    && echo "Expected Claude Code $(cat /tmp/claude-code-latest-version), got $(claude --version)"

# Give node user sudo access
USER root
RUN echo "node ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/node \
    && chmod 0440 /etc/sudoers.d/node

# Bake the kit into the image at a known location.
# Run install-kit-here from a project root to drop
# CLAUDE.md, PROCESS.md, and .claude/ into the current directory.
COPY kit/ /opt/agent-dev-container/
COPY install-kit-here.sh /usr/local/bin/install-kit-here
RUN chmod +x /usr/local/bin/install-kit-here \
    && chmod +x /opt/agent-dev-container/.claude/hooks/*.sh \
    && chmod +x /opt/agent-dev-container/.claude/statusline/*.sh \
    && chown -R node:node /opt/agent-dev-container

USER node
