## Why

当前 gitclone 在克隆仓库时无法使用系统代理（如 Clash VPN），导致在某些网络环境下无法正常克隆仓库，特别是在使用代理工具的场景下。

## What Changes

- 新增**自动代理检测**功能：检测系统 HTTP/SOCKS5 代理并自动应用于 git 操作
- 新增**手动代理配置**选项：支持在配置文件中指定代理地址
- 新增**代理质量检测**：克隆前验证代理连通性
- 支持环境变量 `HTTP_PROXY` / `HTTPS_PROXY` / `ALL_PROXY`

## Capabilities

### New Capabilities

- `proxy-detection`: 自动检测系统代理设置
- `proxy-configuration`: 支持在配置文件中设置自定义代理
- `proxy-health-check`: 代理连通性检测

### Modified Capabilities

- `git-clone`: 修改现有 git clone 流程，增加代理配置步骤

## Impact

- 影响 `gitclone` 命令的克隆逻辑
- 新增配置项：`proxy` 配置节
- 依赖：无新增外部依赖
