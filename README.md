# OpenClaw 飞书插件 Docker 部署

> 通过 Docker 和 Docker Compose 快速部署 OpenClaw + 飞书官方插件

## 功能特性

- **OpenClaw 核心**: AI 驱动的通信与自动化平台
- **飞书插件**: 深度集成飞书，支持消息、文档、日历、任务等
- **国内源优化**: apt/npm/Node.js 使用国内镜像源
- **预装工具**: ifconfig、nano、openssh-server
- **自动升级**: 可配置自动更新 OpenClaw 和飞书插件
- **实时日志**: OpenClaw 运行日志实时输出到 Docker 日志

## 快速开始

### 前置条件

- Docker >= 20.10
- Docker Compose >= 2.0
- 飞书开放平台应用（获取 App ID 和 App Secret）

### 方式 1：使用预构建镜像（推荐）

```bash
# 从阿里云镜像仓库拉取预构建的镜像
docker pull registry.cn-hangzhou.aliyuncs.com/your-namespace/openclaw-feishu:latest
```

### 方式 2：本地构建

```bash
# 克隆项目
git clone https://github.com/runsir/openclaw-docker-feishu.git
cd openclaw-docker-feishu

# 构建镜像
docker build -t openclaw-feishu:latest .
```

### 2. 配置环境变量

```bash
cp .env.example .env
nano .env
```

必须配置以下变量：

```bash
# 飞书应用配置
FEISHU_APP_ID=cli_xxxxxxxxxxxxxxx
FEISHU_APP_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# 大模型配置
API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
BASE_URL=https://api.openai.com/v1
MODEL_ID=gpt-4o

# Gateway 配置
OPENCLAW_GATEWAY_TOKEN=your-gateway-token
```

### 配置说明

#### 1. 飞书配置
- `FEISHU_APP_ID` 和 `FEISHU_APP_SECRET`：在飞书开放平台获取
- `FEISHU_OFFICIAL_PLUGIN_ENABLED`：是否启用飞书官方插件

#### 2. 大模型配置
- `API_KEY`：你的 API 密钥
- `BASE_URL`：API 基础 URL（支持 OpenAI、Claude、阿里云等）
- `MODEL_ID`：模型 ID（支持多个，用逗号分隔）
- `CONTEXT_WINDOW`：上下文窗口大小
- `MAX_TOKENS`：最大输出 tokens

#### 3. Gateway 配置
- `OPENCLAW_GATEWAY_TOKEN`：网关认证令牌
- `OPENCLAW_GATEWAY_BIND`：绑定地址（lan/local/all）
- `OPENCLAW_GATEWAY_PORT`：网关端口

更多配置项请查看 `.env.example` 文件中的详细注释。

### 3. 构建并启动

```bash
# 构建镜像并启动
docker-compose up -d --build

# 查看启动日志
docker-compose logs -f
```

### 4. 首次配置

容器启动后，进入容器完成 OpenClaw 初始化配置：

```bash
# 进入容器
docker exec -it openclaw-feishu bash

# 运行引导配置
openclaw onboard --install-daemon

# 启动 Gateway
openclaw gateway run &
```

### 5. 飞书插件配对

1. 在飞书中向机器人发送消息，获取配对码
2. 在终端执行配对命令：

```bash
openclaw pairing approve feishu <配对码> --notify
```

## 配置说明

### 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `SSH_PORT` | 宿主机 SSH 端口 | 2222 |
| `OPENCLAW_PORT` | OpenClaw Gateway 端口 | 18789 |
| `FEISHU_APP_ID` | 飞书应用 ID | - |
| `FEISHU_APP_SECRET` | 飞书应用密钥 | - |
| `OPENAI_API_KEY` | OpenAI API 密钥 | - |
| `OPENAI_MODEL` | 使用的模型 | gpt-4o |
| `AUTO_UPDATE` | 自动升级开关 | false |
| `UPDATE_CHECK_INTERVAL` | 自动升级间隔(秒) | 3600 |
| `INSTALL_CLAWHUB` | 安装 ClawHub | true |
| `SKILLS_LIST` | 启动时安装的 Skills | - |

### Skills 插件配置

在 `.env` 中配置 `SKILLS_LIST` 变量，用逗号分隔要安装的 Skills：

```bash
# 示例：安装 Brave 浏览器插件和 Coding Agent
SKILLS_LIST=brave,coding-agent

# 示例：安装多个常用 Skills
SKILLS_LIST=brave,coding-agent,web-search,github,filesystem
```

**常用 Skills 列表**：
- `brave` - 浏览器操作插件
- `coding-agent` - 编码助手
- `web-search` - 网页搜索
- `github` - GitHub 集成
- `filesystem` - 文件系统操作
- `notion` - Notion 集成
- `slack` - Slack 集成

### 飞书消息回复模式

```bash
# 仅 @ 机器人时回复（推荐）
openclaw config set channels.feishu.requireMention true --json

# 所有消息都回复
openclaw config set channels.feishu.requireMention false --json
```

## 常用命令

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 查看日志
docker-compose logs -f

# 进入容器
docker exec -it openclaw-feishu bash

# 查看容器状态
docker-compose ps

# 重启服务
docker-compose restart

# 重新构建镜像
docker-compose build --no-cache
```

## 端口说明

| 端口 | 服务 | 说明 |
|------|------|------|
| 2222 | SSH | 宿主机映射端口 |
| 18789 | OpenClaw Gateway | 宿主机映射端口 |

## 远程访问

### 通过 SSH 隧道访问 Dashboard

如果无法直接访问服务器端口，可以通过 SSH 隧道安全地访问 OpenClaw Dashboard：

#### 1. 使用 SSH 命令行

```bash
# 建立 SSH 隧道（将服务器的 18789 端口映射到本地 18789）
ssh -L 18789:localhost:18789 -p 2222 root@<服务器IP>

# 或者使用密钥
ssh -i /path/to/key.pem -L 18789:localhost:18789 -p 2222 root@<服务器IP>
```

#### 2. 访问 Dashboard

隧道建立后，在本地浏览器中打开：

```
http://localhost:18789
```

#### 3. 常用 SSH 隧道选项

```bash
# 后台运行隧道
ssh -f -N -L 18789:localhost:18789 -p 2222 root@<服务器IP>

# 保持连接（避免超时断开）
ssh -o ServerAliveInterval=60 -L 18789:localhost:18789 -p 2222 root@<服务器IP>

# macOS/Linux 添加密钥
ssh -i /path/to/key.pem -o ServerAliveInterval=60 -N -L 18789:localhost:18789 -p 2222 root@<服务器IP>
```

#### 4. Windows 用户

使用 PowerShell 或 PuTTY：

**PowerShell**:
```powershell
ssh -L 18789:localhost:18789 -p 2222 root@<服务器IP>
```

**PuTTY**:
- Connection > SSH > Tunnels
- Source port: 18789
- Destination: localhost:18789
- 点击 "Add" 添加

### 直接访问（仅限内网）

如果网络允许，也可以直接通过浏览器访问：

```
http://<服务器IP>:18789
```

### API Token 访问

如果需要通过 API 访问，可以使用以下方式获取 Token：

```bash
# 进入容器
docker exec -it openclaw-feishu bash

# 查看 Token
openclaw config get apiToken
```

Docker Compose 会自动创建以下卷：

- `openclaw-data`: OpenClaw 配置和数据 (`/root/.openclaw`)
- `openclaw-logs`: OpenClaw 日志 (`/root/.openclaw/logs`)

## 故障排查

```bash
# 检查容器状态
docker-compose ps

# 查看详细日志
docker-compose logs openclaw-feishu

# 进入容器排查
docker exec -it openclaw-feishu bash

# 飞书插件诊断
/feishu doctor

# 尝试自动修复
feishu-plugin-onboard doctor --fix

# 查看版本信息
feishu-plugin-onboard info
```

## 目录结构

```
openclaw-docker-feishu/
├── Dockerfile           # Docker 镜像构建配置
├── docker-compose.yml  # 容器编排配置
├── entrypoint.sh       # 容器启动脚本
├── .env                # 环境变量（敏感信息）
├── .env.example        # 环境变量模板
├── .gitignore
├── README.md           # 项目说明文档
└── memory/             # 工作日志
```

## CI/CD 自动构建

本项目使用 GitHub Actions 自动构建并推送 Docker 镜像到 Docker Hub。

### 自动构建触发条件

- **Push 到 main 分支**：自动构建并推送镜像（标签：`latest`, `main`）
- **创建版本标签**：自动构建并推送带版本号的镜像（如 `v1.0.0`）
- **Pull Request**：自动构建但不推送（用于测试）

### 使用预构建镜像

```bash
docker pull runsir/openclaw-feishu:latest
```

修改 `docker-compose.yml`：

```yaml
services:
  openclaw-feishu:
    image: runsir/openclaw-feishu:latest
    # 不再需要 build 配置
```

启动服务：

```bash
docker-compose up -d
```

### GitHub Secrets 配置

| Secret 名称 | 说明 |
|------------|------|
| `DOCKER_USERNAME` | Docker Hub 用户名 |
| `DOCKER_PASSWORD` | Docker Hub 密码或 Access Token |

详细配置说明请查看 [`.github/workflows/README.md`](.github/workflows/README.md)

### 手动触发构建

进入仓库的 `Actions` 标签页，选择 `Build and Push Docker Image to Aliyun ACR`，点击 `Run workflow`。

## 更新升级

### 手动更新

```bash
# 方式 1: 使用预构建镜像
docker pull runsir/openclaw-feishu:latest
docker-compose up -d

# 方式 2: 本地重新构建
docker-compose build
docker-compose up -d
```

### 自动更新

在 `.env` 中启用：

```bash
AUTO_UPDATE=true
UPDATE_CHECK_INTERVAL=3600  # 每小时检查一次
```

## 注意事项

- 飞书插件暂不支持 Windows 系统
- 确保飞书应用已开启"机器人"能力
- 插件会申请较多飞书权限，请确保在可信环境中使用

## 参考链接

- [OpenClaw 官方文档](https://docs.openclaw.ai/start/getting-started)
- [飞书 OpenClaw 插件介绍](https://www.feishu.cn/content/article/7613711414611463386)
- [飞书开放平台](https://open.feishu.cn/)

## License

MIT
