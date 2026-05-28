# AutoScripts

个人自动化脚本集合，用于提高日常开发效率。

## 📁 目录结构

```
AutoScripts/
├── README.md                    # 本说明文档
├── clone-github-repo.sh         # Git 仓库智能克隆脚本
├── install-gitclone.sh          # gitclone 命令安装脚本
└── gitclone-config.json         # 配置文件（服务器映射和编辑器设置）
```

## 🚀 脚本说明

### gitclone - 智能 Git 仓库克隆工具

一个智能的 Git 仓库克隆工具，支持多个 Git 服务器，自动识别组织结构和仓库名称，并将仓库克隆到对应的目录结构中。

#### ✨ 功能特点

- **多服务器支持**：自动识别不同的 Git 服务器（GitHub、Gitea、Gitee 等）
- **智能目录组织**：根据服务器类型自动创建对应的目录结构
- **多层组织支持**：支持复杂的组织层级结构（如 `org/suborg/repo`）
- **自动路径解析**：自动从 URL 中提取服务器、组织路径和仓库名
- **配置文件支持**：可通过配置文件自定义服务器映射和编辑器列表
- **自动打开仓库**：克隆完成后可选择立即打开仓库，支持多种编辑器
- **友好提示**：彩色输出，清晰的操作反馈

#### 📦 安装方法

1. **运行安装脚本**：
   ```bash
   cd /Users/shenhuanjie/Documents/AutoScripts
   ./install-gitclone.sh
   ```

2. **安装完成后**，可以在任何目录使用 `gitclone` 命令。

#### 🎯 使用方法

##### 基本用法

```bash
gitclone <git-url>
```

##### 支持的服务器

| 服务器 | 目录映射 | 示例 |
|--------|---------|------|
| `github.com` | `~/Documents/Projects/github/` | `gitclone https://github.com/langgenius/dify` |
| `gitea.skyner.cn` | `~/Documents/Projects/gitea/` | `gitclone https://gitea.skyner.cn/org/repo` |
| `gitee.com` | `~/Documents/Projects/gitee/` | `gitclone https://gitee.com/org/repo` |
| `cnb.cool` | `~/Documents/Projects/cnb/` | `gitclone https://cnb.cool/org/repo` |
| 其他服务器 | `~/Documents/Projects/{主机名}/` | 自动使用主机名作为目录名 |

##### 支持的 URL 格式

- **HTTPS 格式**：
  ```bash
  gitclone https://github.com/langgenius/dify
  gitclone https://github.com/org/suborg/repo
  gitclone https://github.com/org/suborg/repo.git
  ```

- **SSH 格式**：
  ```bash
  gitclone git@github.com:langgenius/dify
  gitclone git@github.com:org/suborg/repo
  gitclone git@github.com:org/suborg/repo.git
  ```

##### 使用示例

```bash
# 克隆 GitHub 仓库（单层组织）
gitclone https://github.com/langgenius/dify
# → ~/Documents/Projects/github/langgenius/dify

# 克隆 GitHub 仓库（多层组织）
gitclone https://github.com/org/suborg/repo
# → ~/Documents/Projects/github/org/suborg/repo

# 克隆 Gitea 仓库
gitclone https://gitea.skyner.cn/org/suborg/repo
# → ~/Documents/Projects/gitea/org/suborg/repo

# 克隆 Gitee 仓库
gitclone https://gitee.com/org/suborg/repo
# → ~/Documents/Projects/gitee/org/suborg/repo

# 克隆 CNB 仓库
gitclone https://cnb.cool/org/suborg/repo
# → ~/Documents/Projects/cnb/org/suborg/repo

# 使用 SSH 格式
gitclone git@github.com:langgenius/dify.git
# → ~/Documents/Projects/github/langgenius/dify
```

##### 查看帮助

```bash
gitclone --help
# 或
gitclone -h
```

#### 📂 目录结构说明

脚本会根据 Git URL 自动创建以下目录结构：

```
~/Documents/Projects/
├── github/              # GitHub 仓库
│   └── {组织路径}/
│       └── {仓库名}/
├── gitea/               # Gitea 仓库
│   └── {组织路径}/
│       └── {仓库名}/
└── gitee/               # Gitee 仓库
    └── {组织路径}/
        └── {仓库名}/
```

**示例**：
- `https://github.com/langgenius/dify` → `~/Documents/Projects/github/langgenius/dify`
- `https://github.com/org/suborg/repo` → `~/Documents/Projects/github/org/suborg/repo`

#### ⚙️ 工作原理

1. **读取配置**：从配置文件读取服务器映射、编辑器列表和基础目录（如果存在）
2. **解析 URL**：从 Git URL 中提取服务器地址、组织路径和仓库名
3. **确定目录类型**：根据配置文件或默认映射确定目录名（github/gitea/gitee）
4. **创建目录结构**：自动创建组织路径目录（如果不存在）
5. **执行克隆**：使用 `git clone` 命令克隆仓库到目标目录
6. **生成索引**：自动生成/更新项目目录索引文件（`PROJECTS_INDEX.md`）
7. **打开仓库**：克隆完成后，询问用户是否立即打开，并支持选择编辑器

#### ⚙️ 配置文件

脚本支持通过 `gitclone-config.json` 配置文件自定义行为：

**配置文件位置**：`/Users/shenhuanjie/Documents/AutoScripts/gitclone-config.json`

**配置项说明**：

1. **server_mappings**：服务器域名与目录名的映射
   ```json
   {
     "server_mappings": {
       "github.com": "github",
       "gitea.skyner.cn": "gitea",
       "gitee.com": "gitee",
       "cnb.cool": "cnb"
     }
   }
   ```

2. **editors**：可用的编辑器列表
   ```json
   {
     "editors": [
       {
         "name": "Cursor",
         "command": "cursor",
         "app_path": "/Applications/Cursor.app"
       },
       {
         "name": "VS Code",
         "command": "code",
         "app_path": "/Applications/Visual Studio Code.app"
       }
     ]
   }
   ```

3. **base_dir**：基础目录路径（支持 `~` 展开）
   ```json
   {
     "base_dir": "~/Documents/Projects"
   }
   ```

**完整配置示例**：

```json
{
  "server_mappings": {
    "github.com": "github",
    "gitea.skyner.cn": "gitea",
    "gitee.com": "gitee",
    "cnb.cool": "cnb"
  },
  "editors": [
    {
      "name": "Cursor",
      "command": "cursor",
      "app_path": "/Applications/Cursor.app"
    },
    {
      "name": "VS Code",
      "command": "code",
      "app_path": "/Applications/Visual Studio Code.app"
    },
    {
      "name": "IntelliJ IDEA",
      "command": "idea",
      "app_path": "/Applications/IntelliJ IDEA.app"
    },
    {
      "name": "WebStorm",
      "command": "webstorm",
      "app_path": "/Applications/WebStorm.app"
    }
  ],
  "base_dir": "~/Documents/Projects"
}
```

**注意**：
- 如果配置文件不存在，脚本会使用默认配置
- 编辑器配置中，`command` 和 `app_path` 至少需要配置一个
- 脚本会自动检测编辑器是否可用（检查命令是否存在或应用路径是否存在）

#### 🔧 高级功能

- **目录已存在处理**：如果目标目录已存在，会提示是否覆盖
- **自动创建父目录**：自动创建所有必要的父目录
- **克隆后自动打开**：克隆完成后可选择立即打开仓库
- **多编辑器支持**：支持选择不同的编辑器打开仓库（Cursor、VS Code、IntelliJ IDEA、WebStorm 等）
- **智能编辑器检测**：自动检测系统中可用的编辑器
- **自动生成项目索引**：每次克隆后自动生成/更新项目目录索引文件
- **项目 README 链接**：自动识别每个项目的 README 文件并生成链接
- **错误处理**：友好的错误提示和帮助信息

#### 📋 项目目录索引功能

脚本会在每次克隆完成后，自动在 `~/Documents/Projects/` 目录中生成或更新 `PROJECTS_INDEX.md` 文件。

**索引文件包含**：

1. **项目目录结构**：以目录树形式显示项目级别的结构（只显示到项目目录，不深入项目内部）
2. **项目列表**：列出所有项目，包括：
   - 项目路径
   - README 文件链接（如果存在）

**注意**：
- 只识别最顶层的 Git 仓库，自动忽略子模块和依赖中的 .git 目录
- 例如：`gitea/seven-games/seven-games-uniapp-h5/uni_modules/uni-collapse` 中的 .git 不会被识别为独立项目

**支持的 README 文件格式**：
- `README.md`
- `README.rst`
- `README.txt`
- `README`
- `readme.md`
- `readme.txt`

**手动刷新索引**：

如果需要手动刷新索引文件，可以运行：

```bash
gitclone --refresh
# 或
gitclone -r
# 或
gitclone --update-index
# 或
gitclone -u
```

**索引文件位置**：`~/Documents/Projects/README.md`

#### 📝 注意事项

1. 确保已安装 Git
2. 确保有对应 Git 服务器的访问权限
3. 如果目录已存在，脚本会询问是否覆盖
4. 支持多层组织结构，最后一部分必须是仓库名
5. 配置文件需要有效的 JSON 格式，否则会使用默认配置
6. 打开功能需要编辑器已安装并在 PATH 中，或应用路径正确
7. 脚本使用 `python3` 解析配置文件，确保系统已安装 Python 3
8. 项目索引文件会自动生成，包含目录树和项目 README 链接
9. 索引文件会在每次克隆新仓库后自动更新

## 🛠️ 维护

### 更新脚本

如果需要更新脚本，直接编辑对应的 `.sh` 文件，然后重新运行安装脚本：

```bash
./install-gitclone.sh
```

### 卸载命令

如果需要卸载 `gitclone` 命令，删除符号链接：

```bash
rm /opt/homebrew/bin/gitclone
# 或
rm ~/bin/gitclone
# 或
rm /usr/local/bin/gitclone
```

## 📄 许可证

个人使用脚本，自由使用和修改。

## 🤝 贡献

欢迎提出改进建议和问题反馈。

## 📖 使用流程示例

1. **克隆仓库**：
   ```bash
   gitclone https://github.com/langgenius/dify
   ```

2. **等待克隆完成**，脚本会显示：
   ```
   [成功] 仓库克隆成功！
   [信息] 位置: ~/Documents/Projects/github/langgenius/dify
   
   是否立即打开仓库？(Y/n):
   ```

3. **选择是否打开**：
   - 输入 `Y` 或直接回车：打开仓库
   - 输入 `n`：不打开

4. **如果选择打开**，会显示编辑器选择菜单：
   ```
   [信息] 请选择打开方式:
   
     1. Cursor
     2. VS Code
     3. IntelliJ IDEA
     4. WebStorm
     0. 取消
   
   请输入选项 (0-4):
   ```

5. **选择编辑器**，输入对应数字即可打开仓库。

---

**最后更新**：2026-01-18
