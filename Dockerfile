# OpenClaw 飞书插件 Docker 镜像
# 基于 Ubuntu 22.04

FROM ubuntu:22.04

LABEL maintainer="openclaw-docker-feishu"
LABEL description="OpenClaw with Feishu Plugin"

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV OPENCLAW_VERSION=2026.3.2
ENV NODE_VERSION=22

# ===== 国内软件源配置 =====
# 替换为阿里云镜像源
RUN sed -i 's|http://archive.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list && \
    sed -i 's|http://security.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list

# ===== 安装基础工具 =====
RUN apt-get update && apt-get install -y \
    # 网络工具
    net-tools \
    iputils-ping \
    curl \
    wget \
    # 编辑器
    nano \
    vim \
    # SSH 服务
    openssh-server \
    openssh-client \
    # 基础工具
    ca-certificates \
    gnupg \
    lsb-release \
    # Node.js 依赖
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ===== 安装 Node.js 22.x (使用 NodeSource 官方仓库) =====
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs

# ===== 配置 npm 镜像源 =====
RUN npm config set registry https://registry.npmmirror.com

# ===== 安装 OpenClaw =====
# 方式 1: 尝试使用官方安装脚本
RUN curl -fsSL https://openclaw.ai/install.sh -o /tmp/install.sh && \
    chmod +x /tmp/install.sh && \
    bash /tmp/install.sh || \
    (echo "安装脚本失败，尝试使用 npm 安装..." && \
     npm install -g openclaw@latest)

# ===== 安装飞书官方插件 =====
# 先安装飞书插件 CLI 工具
RUN curl -o /tmp/feishu-openclaw-plugin-onboard-cli.tgz \
    https://sf3-cn.feishucdn.com/obj/open-platform-opendoc/4d184b1ba733bae2423a89e196a2ef8f_QATOjKH1WN.tgz && \
    npm install /tmp/feishu-openclaw-plugin-onboard-cli.tgz -g && \
    rm /tmp/feishu-openclaw-plugin-onboard-cli.tgz

# ===== 配置 SSH 服务 =====
# 创建 SSH 目录
RUN mkdir /var/run/sshd

# 配置 SSH 允许 root 登录（可选，根据需求调整）
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

# ===== 创建 OpenClaw 工作目录 =====
RUN mkdir -p /root/.openclaw

# ===== 复制配置文件 =====
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# ===== 暴露端口 =====
# OpenClaw Gateway 默认端口
EXPOSE 18789
# SSH 端口
EXPOSE 22

# ===== 启动脚本 =====
ENTRYPOINT ["/entrypoint.sh"]
