# gitclone

智能 Git 仓库克隆工具，一行命令搞定仓库克隆 + 目录分类 + 自动打开。

[English](README_EN.md)

## 特性

- **智能目录分类** - 根据 Git 服务器自动分类到对应目录
  - `github.com` → `~/Documents/Projects/github/`
  - `gitea.skyner.cn` → `~/Documents/Projects/gitea/`
  - `gitee.com` → `~/Documents/Projects/gitee/`
- **多 URL 格式支持** - HTTPS / SSH / 多层组织路径
- **网络质量检测** - 克隆前自动检测网络连通性
- **代理支持** - 自动检测并使用系统代理（支持 Clash VPN 等）
- **克隆后交互** - 生成项目索引、选择编辑器打开

## 安装

```bash
curl -fsSL https://raw.githubusercontent.com/shenhuanjie/gitclone/main/install.sh | bash
```

或手动安装：

```bash
git clone https://github.com/shenhuanjie/gitclone.git ~/.gitclone
~/.gitclone/install-gitclone.sh
```

## 使用

```bash
# 基本用法
gitclone https://github.com/langgenius/dify

# 多层组织
gitclone https://github.com/org/suborg/repo

# SSH 格式
gitclone git@github.com:langgenius/dify

# 刷新项目索引
gitclone --refresh
```

## 示例输出

```
==========================================
    智能克隆 Git 仓库工具
==========================================

[信息] Git URL: https://github.com/langgenius/dify
[信息] 服务器: github.com
[信息] 目录类型: github
[信息] 组织路径: langgenius
[信息] 仓库名: dify

[成功] 仓库克隆成功！
[信息] 位置: ~/Documents/Projects/github/langgenius/dify
```

## 配置

配置文件: `~/.gitclone/gitclone-config.json`

```json
{
  "server_mappings": {
    "github.com": "github",
    "gitea.skyner.cn": "gitea",
    "gitee.com": "gitee"
  },
  "editors": [
    { "name": "Cursor", "command": "cursor", "app_path": "/Applications/Cursor.app" },
    { "name": "VS Code", "command": "code", "app_path": "/Applications/Visual Studio Code.app" }
  ],
  "base_dir": "~/Documents/Projects",
  "proxy": {
    "enabled": true,
    "autoDetect": true,
    "url": ""
  }
}
```

### 代理配置说明

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `enabled` | 是否启用代理 | `true` |
| `autoDetect` | 是否自动检测代理 | `true` |
| `url` | 自定义代理地址（优先于自动检测） | `""` |

代理检测优先级：配置 URL > 环境变量 > 常见端口 > macOS 系统代理

## 目录结构

```
~/Documents/Projects/
├── github/
│   └── {org}/
│       └── {repo}/
├── gitea/
│   └── {org}/
│       └── {repo}/
└── gitee/
    └── {org}/
        └── {repo}/
```

## License

MIT

## CHANGELOG

### [Unreleased]

### [1.0.0] - 2026-05-28

#### Added
- 代理支持功能
  - 自动检测系统代理（环境变量、常见端口、macOS 系统代理）
  - 支持自定义代理配置
  - 代理健康检查
  - Git 克隆前自动应用代理配置
- 项目目录索引生成
- 多编辑器支持
