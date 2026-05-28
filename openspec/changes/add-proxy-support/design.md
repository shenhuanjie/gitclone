## Context

gitclone 当前直接调用 `git clone` 命令，不支持代理。在中国大陆等网络受限环境下，用户常使用 Clash 等代理工具，但 gitclone 无法自动利用这些代理。

## Goals / Non-Goals

**Goals:**
- 自动检测并使用系统 HTTP/SOCKS5 代理
- 支持用户自定义代理配置
- 克隆前验证代理连通性

**Non-Goals:**
- 不支持代理认证（用户名/密码）
- 不支持 PAC 脚本解析

## Decisions

### 1. 代理检测优先级

```
环境变量 ALL_PROXY/HTTP_PROXY/HTTPS_PROXY
    ↓
Clash 默认端口 (7890, 7891, 1080)
    ↓
系统代理设置 (macOS: scutil --proxy)
```

**为什么**：环境变量是标准做法，优先级最高；Clash 是最流行的代理工具，默认端口作为备选。

### 2. 配置项结构

```json
{
  "proxy": {
    "enabled": true,
    "autoDetect": true,
    "url": "http://127.0.0.1:7890"
  }
}
```

**为什么**：`enabled` 允许禁用代理检测；`autoDetect` 控制是否自动检测；`url` 提供手动指定。

### 3. Git 代理应用方式

通过设置 `git config http.proxy` 和 `git config https.proxy` 实现，而非传入命令行参数。

**为什么**：更简洁，支持所有 git 子命令，且对用户透明。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 代理端口冲突 | 提供手动配置选项 |
| 代理无响应导致克隆超时 | 健康检查 + 回退直接连接 |
| 多代理工具同时运行 | 按优先级检测，使用第一个可用的 |
