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
  "base_dir": "~/Documents/Projects"
}
```

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
