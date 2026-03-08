# openclaw-docker-feishu 项目记忆

## 项目概述

- **项目名称**: openclaw-docker-feishu
- **项目类型**: OpenClaw 飞书官方插件的 Docker 部署项目
- **创建日期**: 2026-03-08
- **官方文档**: https://docs.openclaw.ai/start/getting-started
- **飞书插件介绍**: https://www.feishu.cn/content/article/7613711414611463386

## OpenClaw 核心概念

OpenClaw 是一个 AI 驱动的通信与自动化平台，充当"智能网关"连接用户与 AI 助手。

### 核心组件
- **Gateway (网关)**: 系统核心，负责消息路由、代理调度、工具执行
- **Channels (通道)**: 扩展组件，对应通信协议/平台（SMS、WhatsApp、Telegram、飞书等）
- **Agents (代理)**: 封装 AI 模型逻辑，处理自然语言理解与生成
- **Tools (工具)**: AI 可调用的功能模块
- **Control UI**: Web 管理控制台

### 飞书插件功能
| 类别 | 能力 |
|------|------|
| 消息 | 读取群聊/单聊历史、发送/回复消息、搜索消息、下载图片/文件 |
| 文档 | 创建、更新、读取云文档内容 |
| 多维表格 | 创建/管理表格、字段、记录、视图 |
| 日历日程 | 管理日历、创建/查询/修改/删除日程 |
| 任务 | 创建/查询/更新/完成任务、管理清单和子任务 |

### 安装前置条件
- OpenClaw 版本 >= 2026.2.26
- 飞书开放平台创建自建应用，开启机器人能力
- Node.js >= 22

## 技术栈

- **基础镜像**: Ubuntu 22.04
- **运行时**: Node.js 22.x（通过 nvm/二进制安装）
- **容器化**: Docker + Docker Compose
- **包管理**: npm（使用淘宝镜像源）

## 架构决策

### 部署架构
```
┌─────────────────────────────────────────┐
│           宿主机 (Host)                  │
│  ┌───────────────────────────────────┐  │
│  │     Docker Container              │  │
│  │  ┌─────────────────────────────┐│  │
│  │  │  OpenClaw Gateway (18789)    ││  │
│  │  │  + 飞书插件                   ││  │
│  │  │  + SSH Server (22)           ││  │
│  │  └─────────────────────────────┘│  │
│  └───────────────────────────────────┘  │
│         ports: 2222:22, 18789:18789     │
└─────────────────────────────────────────┘
```

### 配置文件结构
```
├── Dockerfile           # 镜像构建配置
├── docker-compose.yml  # 容器编排
├── .env                # 敏感配置（需手动创建）
├── .env.example        # 配置模板
├── .gitignore
├── entrypoint.sh       # 容器启动脚本
└── memory/             # 工作日志
```

### 环境变量设计
| 变量 | 说明 |
|------|------|
| SSH_PORT | 宿主机 SSH 端口映射 |
| OPENCLAW_PORT | OpenClaw Gateway 端口 |
| FEISHU_APP_ID | 飞书应用 ID |
| FEISHU_APP_SECRET | 飞书应用密钥 |
| OPENAI_API_KEY | OpenAI API 密钥 |
| OPENAI_MODEL | 使用的模型 |
| AUTO_UPDATE | 自动升级开关 (true/false) |
| UPDATE_CHECK_INTERVAL | 自动升级检查间隔 (秒) |

### 国内源配置
- **apt 镜像**: 阿里云镜像 (`mirrors.aliyun.com`)
- **npm 镜像**: 淘宝镜像 (`registry.npmmirror.com`)
- **Node.js**: 从 nodejs.org 或淘宝镜像下载

### 预装工具
- `net-tools` (ifconfig)
- `nano` (编辑器)
- `openssh-server` (SSH 服务)

## 关键代码模式

待发现...

## 已知问题

- 暂不支持 Windows 系统

## 错误历史

无

## 重要变更记录

- 2026-03-08: 项目初始化，添加关键文档信息
- 2026-03-08: 创建 Docker 部署配置（Dockerfile、docker-compose.yml、.env.example）
- 2026-03-08: 添加自动升级功能及开关配置
- 2026-03-08: 添加 OpenClaw 实时日志输出到 Docker 日志
