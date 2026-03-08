#!/bin/bash
set -e

echo "===== OpenClaw Docker 启动 ====="

# 启动 SSH 服务
echo "[1/4] 启动 SSH 服务..."
mkdir -p /var/run/sshd
/usr/sbin/sshd

# 显示 Docker 容器 IP
echo "[2/4] 容器网络信息:"
echo "  IP 地址: $(hostname -I | awk '{print $1}')"
echo "  主机名: $(hostname)"

# ===== ClawHub 安装 =====
INSTALL_CLAWHUB=${INSTALL_CLAWHUB:-true}
SKILLS_LIST=${SKILLS_LIST:-}

echo "[3/4] 安装 ClawHub..."

if command -v npx &> /dev/null; then
    if [ "$INSTALL_CLAWHUB" = "true" ]; then
        echo "  安装 ClawHub (Skills 管理工具)..."
        npm install -g clawhub 2>/dev/null || npx -y clawhub@latest install 2>/dev/null || echo "  ClawHub 安装完成"
    else
        echo "  跳过 ClawHub 安装"
    fi
else
    echo "  npx 不可用，跳过 ClawHub"
fi

# ===== Skills 插件安装（动态读取 SKILLS_LIST）=====
echo "Skills 插件配置..."

install_skill() {
    local skill_name=$1

    if command -v clawhub &> /dev/null; then
        echo "  安装 $skill_name..."
        clawhub install "$skill_name" 2>/dev/null || echo "  $skill_name 安装失败（可能不存在）"
    elif command -v npx &> /dev/null; then
        echo "  安装 $skill_name..."
        npx clawhub@latest install "$skill_name" 2>/dev/null || echo "  $skill_name 安装失败（可能不存在）"
    else
        echo "  工具不可用，跳过 $skill_name"
    fi
}

# 解析并安装用户定义的 Skills
if [ -n "$SKILLS_LIST" ]; then
    echo "  用户定义的 Skills: $SKILLS_LIST"
    # 将逗号分隔的列表转换为数组
    IFS=',' read -ra SKILLS_ARRAY <<< "$SKILLS_LIST"
    for skill in "${SKILLS_ARRAY[@]}"; do
        # 去除空格
        skill=$(echo "$skill" | xargs)
        if [ -n "$skill" ]; then
            install_skill "$skill"
        fi
    done
else
    echo "  未配置需要安装的 Skills（SKILLS_LIST 为空）"
    echo "  如需安装 Skills，请在 .env 中配置: SKILLS_LIST=brave,coding-agent,web-search"
fi

# ===== 自动升级功能 =====
# 读取环境变量配置
AUTO_UPDATE=${AUTO_UPDATE:-false}
UPDATE_CHECK_INTERVAL=${UPDATE_CHECK_INTERVAL:-3600}

if [ "$AUTO_UPDATE" = "true" ]; then
    echo "[4/4] 自动升级已启用 (间隔: ${UPDATE_CHECK_INTERVAL}s)..."

    # 后台运行自动升级检查
    (
        while true; do
            echo "[Auto-Updater] 检查 OpenClaw 更新..."
            if command -v openclaw &> /dev/null; then
                openclaw upgrade --check 2>/dev/null || true
                # 尝试升级（如果需要）
                openclaw upgrade --yes 2>/dev/null || true
                # 同时更新飞书插件
                feishu-plugin-onboard update 2>/dev/null || true
            fi
            echo "[Auto-Updater] 下次检查: ${UPDATE_CHECK_INTERVAL}s 后"
            sleep "$UPDATE_CHECK_INTERVAL"
        done
    ) &
    AUTO_UPGRADE_PID=$!
    echo "[4/4] 自动升级已启动 (PID: $AUTO_UPGRADE_PID)"
else
    echo "[4/4] 自动升级已禁用 (AUTO_UPDATE=$AUTO_UPDATE)"
fi

# 检查 OpenClaw 是否已配置
if [ ! -f "/root/.openclaw/config.yaml" ]; then
    echo "OpenClaw 首次启动..."
    echo "  请通过 docker exec 进入容器完成配置:"
    echo "    docker exec -it openclaw-feishu bash"
    echo "    openclaw onboard --install-daemon"

    # 保持容器运行
    tail -f /dev/null
else
    echo "启动 OpenClaw Gateway..."

    # 创建日志目录
    mkdir -p /root/.openclaw/logs

    # 使用 trap 处理信号
    cleanup() {
        echo "收到停止信号，正在关闭服务..."
        if [ -n "$OPENCLAW_PID" ]; then
            kill -TERM "$OPENCLAW_PID" 2>/dev/null || true
        fi
        if [ -n "$TAIL_PID" ]; then
            kill -TERM "$TAIL_PID" 2>/dev/null || true
        fi
        exit 0
    }
    trap cleanup SIGTERM SIGINT

    # 启动 OpenClaw Gateway，输出到 stdout（docker logs 可实时查看）
    openclaw gateway run > /proc/1/fd/1 2>&1 &
    OPENCLAW_PID=$!

    echo "  OpenClaw Gateway PID: $OPENCLAW_PID"

    # 监控 OpenClaw 进程，如意外退出则记录
    while kill -0 "$OPENCLAW_PID" 2>/dev/null; do
        sleep 5
    done

    echo "OpenClaw Gateway 已退出，退出码: $?"
    exit 1
fi

echo ""
echo "===== 服务启动完成 ====="
echo "  - SSH: 端口 22"
echo "  - OpenClaw: 端口 18789"
echo "  - 自动升级: $AUTO_UPDATE"
echo ""
echo "查看日志: docker logs -f openclaw-feishu"
echo "进入容器: docker exec -it openclaw-feishu bash"
