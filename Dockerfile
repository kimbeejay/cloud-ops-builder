FROM debian:bookworm-slim

LABEL org.opencontainers.image.source="https://github.com/kimbeejay/cloud-ops-builder"
LABEL org.opencontainers.image.title="Cloud Ops Builder"
LABEL org.opencontainers.image.description="A tool to build and deploy cloud operations tools."
LABEL org.opencontainers.image.licenses="Apache-2.0"

ENV DEBIAN_FRONTEND=noninteractive

ARG TARGETARCH

RUN echo "Building for architecture: ${TARGETARCH}"

# 1. Install essential system tools
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    unzip \
    git \
    xz-utils \
    gnupg \
    make \
    && rm -rf /var/lib/apt/lists/*

# 2. Node.js v24 (Manual binary install for multi-arch precision)
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash && \
    export NVM_DIR="$HOME/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    nvm install 24 && \
    nvm use 24 && \
    nvm alias 24 && \
    ln -s $(which node) /usr/local/bin/node && \
    ln -s $(which npm) /usr/local/bin/npm && \
    node -v && npm -v

# 3. Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install -i /usr/local/aws-cli -b /usr/local/bin && \
    rm -rf awscliv2.zip aws && \
    aws --version

# 4. Install kubectl
RUN KUBE_LATEST_VERSION=$(curl -s https://dl.k8s.io/release/stable.txt) && \
    curl -LO "https://dl.k8s.io/release/${KUBE_LATEST_VERSION}/bin/linux/${TARGETARCH}/kubectl" && \
    mv kubectl /usr/local/bin/ && \
    chmod +x /usr/local/bin/kubectl && \
    kubectl version --client

# 5. Install Helm
RUN curl -o- https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash && \
    helm version --short

# 6. Install uv
COPY --from=ghcr.io/astral-sh/uv:0.11.8 /uv /uvx /bin/
RUN uv python install 3.12 && \
    PYTHON_PATH=$(uv python find 3.12) && \
    ln -sf "$PYTHON_PATH" /usr/local/bin/python3.12 && \
    ln -sf "$PYTHON_PATH" /usr/local/bin/python3 && \
    ln -sf "$PYTHON_PATH" /usr/local/bin/python

ENV UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1 \
    PYTHONUNBUFFERED=1

# 7. Install Docker CLI and Docker Compose
RUN install -m 0755 -d /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
RUN chmod a+r /etc/apt/keyrings/docker.asc
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bookworm stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

RUN apt-get update && apt-get install -y docker-ce-cli && rm -rf /var/lib/apt/lists/*

WORKDIR /app
