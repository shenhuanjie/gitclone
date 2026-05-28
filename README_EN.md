# gitclone

Intelligent Git repository cloning tool - one command to clone repos + organize directories + auto-open.

[中文](README.md)

## Features

- **Smart Directory Organization** - Automatically categorize repos by Git server
  - `github.com` → `~/Documents/Projects/github/`
  - `gitea.skyner.cn` → `~/Documents/Projects/gitea/`
  - `gitee.com` → `~/Documents/Projects/gitee/`
- **Multi-URL Format Support** - HTTPS / SSH / multi-level org paths
- **Network Quality Detection** - Check connectivity before cloning
- **Proxy Support** - Auto-detect and use system proxy (Clash VPN, etc.)
- **Post-Clone Interaction** - Generate project index, choose editor to open

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/shenhuanjie/gitclone/main/install.sh | bash
```

Or manually:

```bash
git clone https://github.com/shenhuanjie/gitclone.git ~/.gitclone
~/.gitclone/install-gitclone.sh
```

## Usage

```bash
# Basic usage
gitclone https://github.com/langgenius/dify

# Multi-level org
gitclone https://github.com/org/suborg/repo

# SSH format
gitclone git@github.com:langgenius/dify

# Refresh project index
gitclone --refresh
```

## Example Output

```
==========================================
    Git Repository Cloning Tool
==========================================

[Info] Git URL: https://github.com/langgenius/dify
[Info] Server: github.com
[Info] Directory Type: github
[Info] Org Path: langgenius
[Info] Repo Name: dify

[Success] Repository cloned!
[Info] Location: ~/Documents/Projects/github/langgenius/dify
```

## Configuration

Config file: `~/.gitclone/gitclone-config.json`

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

### Proxy Configuration

| Option | Description | Default |
|--------|-------------|---------|
| `enabled` | Enable proxy | `true` |
| `autoDetect` | Auto-detect proxy | `true` |
| `url` | Custom proxy URL (takes priority over auto-detect) | `""` |

Proxy detection priority: Config URL > Environment vars > Common ports > macOS System Proxy

## Directory Structure

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
- Proxy support
  - Auto-detect system proxy (env vars, common ports, macOS)
  - Custom proxy configuration
  - Proxy health check
  - Auto-apply proxy before git clone
- Project directory index generation
- Multi-editor support
