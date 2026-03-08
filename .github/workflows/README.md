# GitHub Actions 配置说明

本文档说明如何配置 GitHub Actions 自动构建并推送 Docker 镜像到 Docker Hub 和/或阿里云容器镜像服务（ACR）。

## 镜像仓库说明

本项目支持同时推送到以下镜像仓库：

### 1. Docker Hub（必需）
- **用途**：主要的镜像仓库，生态成熟，访问速度快
- **是否必需**：是
- **免费额度**：无限

### 2. 阿里云容器镜像服务（可选）
- **用途**：国内访问速度快，适合国内用户
- **是否必需**：否（可选）
- **免费额度**：个人版无限

---

## 前置准备

### 1. Docker Hub 账号（必需）

如果没有 Docker Hub 账号，请先注册：

1. 访问 [Docker Hub](https://hub.docker.com/)
2. 点击 "Sign Up" 注册账号
3. 完成邮箱验证

### 2. 创建 Docker Hub Access Token（推荐）

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

### 3. 阿里云容器镜像服务（可选）

如果需要推送到阿里云 ACR：

1. 登录阿里云控制台
2. 进入「容器镜像服务」
3. 创建个人版或企业版实例
4. 创建命名空间（Namespace）和镜像仓库

### 4. 获取阿里云访问凭证（可选）

#### 方式 1：使用阿里云 RAM 用户（推荐）

1. 登录阿里云控制台
2. 进入「RAM 访问控制」
3. 创建 RAM 用户
4. 为用户授予 `AliyunContainerRegistryFullAccess` 权限
5. 创建 AccessKey（AccessKey ID 和 AccessKey Secret）

#### 方式 2：使用容器镜像服务专用密码

1. 登录阿里云容器镜像服务
2. 点击右上角头像 -> 访问凭证
3. 设置固定密码

---

## GitHub Secrets 配置

在 GitHub 仓库中配置以下 Secrets：

### 路径
```
仓库 -> Settings -> Secrets and variables -> Actions -> New repository secret
```

### 必需配置的 Secrets（Docker Hub）

| Secret 名称 | 说明 | 示例值 |
|------------|------|--------|
| `DOCKER_USERNAME` | Docker Hub 用户名 | `runsir` |
| `DOCKER_PASSWORD` | Docker Hub 密码或 Access Token | `dckr_pat_xxxxx` |

### 可选配置的 Secrets（阿里云 ACR）

| Secret 名称 | 说明 | 示例值 |
|------------|------|--------|
| `ALIYUN_REGISTRY` | 阿里云镜像仓库地址 | `registry.cn-hangzhou.aliyuncs.com` |
| `ALIYUN_USERNAME` | 阿里云用户名 | RAM 用户名或阿里云账号 |
| `ALIYUN_PASSWORD` | 阿里云密码 | RAM AccessKey Secret 或固定密码 |
| `IMAGE_NAMESPACE` | 命名空间（可选） | `your-namespace` 或 `library` |

---

## 配置示例

### Docker Hub 配置（必需）

1. **DOCKER_USERNAME**
   ```
   runsir
   ```

2. **DOCKER_PASSWORD**
   ```
   dckr_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
   如果使用 Access Token，格式通常是 `dckr_pat_` 开头

### 阿里云 ACR 配置（可选）

如果配置了以下 Secrets，镜像会同时推送到阿里云 ACR：

1. **ALIYUN_REGISTRY**
   ```
   registry.cn-hangzhou.aliyuncs.com
   ```

2. **ALIYUN_USERNAME**
   ```
   your-aliyun-username
   ```

3. **ALIYUN_PASSWORD**
   ```
   your-access-key-secret-or-password
   ```

4. **IMAGE_NAMESPACE**（可选）
   ```
   your-namespace
   ```
   如果不配置，默认使用 `library`

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

### 从 Docker Hub 拉取（推荐）

```bash
docker pull runsir/openclaw-feishu:latest
```

### 从阿里云 ACR 拉取（国内用户更快）

```bash
docker pull registry.cn-hangzhou.aliyuncs.com/your-namespace/openclaw-feishu:latest
```

### 使用 docker-compose

修改 `docker-compose.yml`：

**使用 Docker Hub 镜像：**
```yaml
services:
  openclaw-feishu:
    image: runsir/openclaw-feishu:latest
    # 不再需要 build 配置
```

**使用阿里云 ACR 镜像：**
```yaml
services:
  openclaw-feishu:
    image: registry.cn-hangzhou.aliyuncs.com/your-namespace/openclaw-feishu:latest
    # 不再需要 build 配置
```

### 直接运行

**使用 Docker Hub 镜像：**
```bash
docker run -d \
  --name openclaw-feishu \
  -p 2222:22 \
  -p 18789:18789 \
  --env-file .env \
  runsir/openclaw-feishu:latest
```

**使用阿里云 ACR 镜像：**
```bash
docker run -d \
  --name openclaw-feishu \
  -p 2222:22 \
  -p 18789:18789 \
  --env-file .env \
  registry.cn-hangzhou.aliyuncs.com/your-namespace/openclaw-feishu:latest
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
