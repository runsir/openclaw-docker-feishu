# GitHub Actions 配置说明

本文档说明如何配置 GitHub Actions 自动构建并推送 Docker 镜像到阿里云容器镜像服务（ACR）。

## 前置准备

### 1. 阿里云容器镜像服务（ACR）

如果没有阿里云容器镜像服务，请先创建：

1. 登录阿里云控制台
2. 进入「容器镜像服务」
3. 创建个人版或企业版实例
4. 创建命名空间（Namespace）和镜像仓库

### 2. 获取阿里云访问凭证

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

### 3. 获取镜像仓库地址

镜像仓库地址格式：
```
registry.<region>.aliyuncs.com
```

常用区域：
- 华东1（杭州）：`registry.cn-hangzhou.aliyuncs.com`
- 华东2（上海）：`registry.cn-shanghai.aliyuncs.com`
- 华南1（深圳）：`registry.cn-shenzhen.aliyuncs.com`
- 华北2（北京）：`registry.cn-beijing.aliyuncs.com`

## GitHub Secrets 配置

在 GitHub 仓库中配置以下 Secrets：

### 路径
```
仓库 -> Settings -> Secrets and variables -> Actions -> New repository secret
```

### 需要配置的 Secrets

| Secret 名称 | 说明 | 示例值 |
|------------|------|--------|
| `ALIYUN_REGISTRY` | 阿里云镜像仓库地址 | `registry.cn-hangzhou.aliyuncs.com` |
| `ALIYUN_USERNAME` | 阿里云用户名 | RAM 用户名或阿里云账号 |
| `ALIYUN_PASSWORD` | 阿里云密码 | RAM AccessKey Secret 或固定密码 |
| `IMAGE_NAMESPACE` | 命名空间（可选） | `your-namespace` 或 `library` |

### 配置示例

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

### 拉取镜像

```bash
docker pull registry.cn-hangzhou.aliyuncs.com/your-namespace/openclaw-feishu:latest
```

### 使用 docker-compose

修改 `docker-compose.yml`：

```yaml
services:
  openclaw-feishu:
    image: registry.cn-hangzhou.aliyuncs.com/your-namespace/openclaw-feishu:latest
    # 不再需要 build 配置
```

### 直接运行

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
- 检查命名空间和镜像仓库是否存在
- 确认 RAM 用户是否有推送权限
- 检查 `IMAGE_NAMESPACE` 是否正确

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
2. **定期轮换 AccessKey**：建议每 3-6 个月更新一次
3. **使用 RAM 用户最小权限**：只授予必要的权限
4. **启用镜像扫描**：在阿里云 ACR 中启用安全扫描
5. **使用镜像签名**：使用 Docker Content Trust 签名镜像

## 更多信息

- [GitHub Actions 官方文档](https://docs.github.com/en/actions)
- [阿里云容器镜像服务文档](https://help.aliyun.com/product/60716.html)
- [Docker Buildx 文档](https://docs.docker.com/buildx/working-with-buildx/)
