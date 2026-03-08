# GitHub Actions 配置说明

本文档说明如何配置 GitHub Actions 自动构建并推送 Docker 镜像到 Docker Hub。

## 前置准备

### 1. Docker Hub 账号

如果没有 Docker Hub 账号，请先注册：

1. 访问 [Docker Hub](https://hub.docker.com/)
2. 点击 "Sign Up" 注册账号
3. 完成邮箱验证

### 2. 创建 Access Token（推荐）

为了安全起见，建议使用 Access Token 而不是密码：

1. 登录 Docker Hub
2. 点击右上角头像 -> **Account Settings**
3. 选择 **Security** 标签
4. 在 **Access Tokens** 部分点击 **New Access Token**
5. 输入描述（如：GitHub Actions）
6. 选择权限（建议选择：Read, Write, Delete）
7. 点击 **Generate** 生成 Token
8. **重要：复制并保存 Token**（只显示一次）

> **注意**：也可以直接使用 Docker Hub 密码，但不推荐。

## GitHub Secrets 配置

在 GitHub 仓库中配置以下 Secrets：

### 路径
```
仓库 -> Settings -> Secrets and variables -> Actions -> New repository secret
```

### 需要配置的 Secrets

| Secret 名称 | 说明 | 示例值 |
|------------|------|--------|
| `DOCKER_USERNAME` | Docker Hub 用户名 | `runsir` |
| `DOCKER_PASSWORD` | Docker Hub 密码或 Access Token | `dckr_pat_xxxxx` |

### 配置示例

1. **DOCKER_USERNAME**
   ```
   runsir
   ```

2. **DOCKER_PASSWORD**
   ```
   dckr_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
   如果使用 Access Token，格式通常是 `dckr_pat_` 开头

## 镜像标签策略

GitHub Actions 会自动生成以下标签：

### Push 到 main 分支
- `latest` - 最新版本
- `main` - 主分支版本

### 创建标签（如 v1.0.0）
- `1.0.0` - 完整版本号
- `1.0` - 主版本.次版本
- `1` - 主版本
- `latest` - 最新版本

### Pull Request
- `pr-<number>` - PR 编号（仅构建，不推送）

## 使用镜像

### 拉取镜像

```bash
docker pull runsir/openclaw-feishu:latest
```

### 使用 docker-compose

修改 `docker-compose.yml`：

```yaml
services:
  openclaw-feishu:
    image: runsir/openclaw-feishu:latest
    # 不再需要 build 配置
```

### 直接运行

```bash
docker run -d \
  --name openclaw-feishu \
  -p 2222:22 \
  -p 18789:18789 \
  --env-file .env \
  runsir/openclaw-feishu:latest
```

## 触发构建

### 自动触发

- **Push 到 main 分支**：自动构建并推送镜像
- **创建版本标签**：自动构建并推送带版本号的镜像
- **Pull Request**：自动构建但不推送（用于测试）

### 手动触发

使用 GitHub Actions 手动运行工作流：

1. 进入仓库的 `Actions` 标签页
2. 选择 `Build and Push Docker Image to Aliyun ACR`
3. 点击 `Run workflow`
4. 选择分支，点击 `Run workflow`

## 故障排查

### 1. 登录失败

**错误信息**：`Error: Username and password required`

**解决方案**：
- 检查 GitHub Secrets 中的 `ALIYUN_USERNAME` 和 `ALIYUN_PASSWORD` 是否正确
- 确认阿里云密码是否有效（RAM AccessKey 可能会过期）

### 2. 推送失败

**错误信息**：`Error: denied: requested access to the resource is denied`

**解决方案**：
- 检查 Docker Hub 用户名是否正确
- 确认 Access Token 或密码是否有效
- 确认镜像名称是否存在拼写错误

## 更多信息

- [GitHub Actions 官方文档](https://docs.github.com/en/actions)
- [Docker Hub 官方文档](https://docs.docker.com/docker-hub/)
- [Docker Buildx 文档](https://docs.docker.com/buildx/working-with-buildx/)
- [Docker Hub Access Token 文档](https://docs.docker.com/security/for-developers/access-tokens/)

### 3. 构建超时

**解决方案**：
- 检查网络连接
- 减少 `platforms` 配置（只构建 amd64）

## 构建配置优化

### 仅构建 amd64 平台（更快）

修改 `.github/workflows/docker-build.yml`：

```yaml
- name: Build and push Docker image
  uses: docker/build-push-action@v5
  with:
    context: .
    platforms: linux/amd64  # 只构建 amd64
    # ...
```

### 添加构建参数

在 `docker-compose.yml` 中添加构建参数：

```yaml
- name: Build and push Docker image
  uses: docker/build-push-action@v5
  with:
    context: .
    build-args: |
      OPENCLAW_VERSION=2026.3.2
      NODE_VERSION=22
    # ...
```

## 安全建议

1. **不要在代码中硬编码密码**：始终使用 GitHub Secrets
2. **定期轮换 Access Token**：建议每 3-6 个月更新一次
3. **使用最小权限**：Access Token 只授予必要的权限
4. **启用镜像扫描**：在 Docker Hub 中启用安全扫描
5. **使用镜像签名**：使用 Docker Content Trust 签名镜像

## 更多信息

- [GitHub Actions 官方文档](https://docs.github.com/en/actions)
- [Docker Hub 官方文档](https://docs.docker.com/docker-hub/)
- [Docker Buildx 文档](https://docs.docker.com/buildx/working-with-buildx/)
- [Docker Hub Access Token 文档](https://docs.docker.com/security/for-developers/access-tokens/)
