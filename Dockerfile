ARG UV_VERSION=0.11.21
FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv-binaries

FROM debian:bookworm-slim

LABEL org.opencontainers.image.source="https://github.com/kimbeejay/cloud-ops-builder"
LABEL org.opencontainers.image.title="Cloud Ops Builder"
LABEL org.opencontainers.image.description="A tool to build and deploy cloud operations tools."
LABEL org.opencontainers.image.licenses="Apache-2.0"

ENV DEBIAN_FRONTEND=noninteractive

ARG TARGETARCH
ARG JQ_VERSION=1.8.1
ARG PYTHON_VERSION=3.12
ARG PNPM_VERSION=11

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
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash && \
    export NVM_DIR="$HOME/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    nvm install 24 && \
    nvm use 24 && \
    nvm alias 24 && \
    ln -sf $(which node) /usr/local/bin/node && \
    ln -sf $(which npm) /usr/local/bin/npm && \
    ln -sf $(which npx) /usr/local/bin/npx && \
    ln -sf $(which corepack) /usr/local/bin/corepack && \
    corepack enable && \
    corepack prepare pnpm@${PNPM_VERSION} --activate && \
    ln -sf $(which pnpm) /usr/local/bin/pnpm && \
    node -v && npm -v && corepack --version && pnpm -v

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
COPY --from=uv-binaries /uv /uvx /bin/
RUN uv python install ${PYTHON_VERSION} && \
    PYTHON_PATH=$(uv python find ${PYTHON_VERSION}) && \
    ln -sf "$PYTHON_PATH" /usr/local/bin/python${PYTHON_VERSION} && \
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

# 8. Install jq
RUN curl "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-${TARGETARCH}" -L -o /usr/local/bin/jq && \
    chmod +x /usr/local/bin/jq && \
    jq --version

# 9. Install databricks-cli
RUN curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/v1.3.0/install.sh | bash && \
    databricks --version

# 10. Install Terraform
RUN TF_LATEST_VERSION=1.15.6 && \
    curl -LO "https://releases.hashicorp.com/terraform/${TF_LATEST_VERSION}/terraform_${TF_LATEST_VERSION}_linux_${TARGETARCH}.zip" && \
    unzip terraform_${TF_LATEST_VERSION}_linux_${TARGETARCH}.zip -d terraform && \
    mv terraform/terraform /usr/local/bin/ && \
    rm terraform_${TF_LATEST_VERSION}_linux_${TARGETARCH}.zip && \
    rm -rf terraform && \
    terraform version

WORKDIR /app
