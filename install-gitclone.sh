#!/bin/bash
# 安装 gitclone 命令到系统 PATH
# 用法: ./install-gitclone.sh

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[信息]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="$SCRIPT_DIR/clone-github-repo.sh"
TARGET_NAME="gitclone"
OLD_TARGET_NAME="github-clone"

# 检查源脚本是否存在
if [ ! -f "$SOURCE_SCRIPT" ]; then
    print_error "找不到源脚本: $SOURCE_SCRIPT"
    exit 1
fi

# 确保源脚本有执行权限
chmod +x "$SOURCE_SCRIPT"

# 查找可用的安装目录
INSTALL_DIR=""
if [ -d "$HOME/bin" ] && [[ ":$PATH:" == *":$HOME/bin:"* ]]; then
    INSTALL_DIR="$HOME/bin"
    print_info "使用用户目录: $INSTALL_DIR"
elif [ -w "/usr/local/bin" ]; then
    INSTALL_DIR="/usr/local/bin"
    print_info "使用系统目录: $INSTALL_DIR"
elif [ -w "/opt/homebrew/bin" ]; then
    INSTALL_DIR="/opt/homebrew/bin"
    print_info "使用 Homebrew 目录: $INSTALL_DIR"
else
    # 尝试创建 ~/bin 目录
    if mkdir -p "$HOME/bin" 2>/dev/null; then
        INSTALL_DIR="$HOME/bin"
        print_info "创建用户目录: $INSTALL_DIR"
        print_warning "请确保 $HOME/bin 在您的 PATH 中"
        print_info "可以将以下内容添加到 ~/.zshrc 或 ~/.bashrc:"
        print_info "  export PATH=\"\$HOME/bin:\$PATH\""
    else
        print_error "无法找到可写的安装目录"
        print_info "请手动创建 ~/bin 目录或使用 sudo 安装到 /usr/local/bin"
        exit 1
    fi
fi

# 卸载旧命令（如果存在）
OLD_TARGET_PATH="$INSTALL_DIR/$OLD_TARGET_NAME"
if [ -L "$OLD_TARGET_PATH" ] || [ -f "$OLD_TARGET_PATH" ]; then
    print_info "发现旧命令: $OLD_TARGET_NAME"
    print_info "正在卸载旧命令..."
    rm -f "$OLD_TARGET_PATH"
    print_success "已卸载旧命令"
    echo ""
fi

TARGET_PATH="$INSTALL_DIR/$TARGET_NAME"

# 检查是否已存在
if [ -L "$TARGET_PATH" ] || [ -f "$TARGET_PATH" ]; then
    print_warning "命令已存在: $TARGET_PATH"
    read -p "是否覆盖？(y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "安装已取消"
        exit 0
    fi
    rm -f "$TARGET_PATH"
fi

# 创建符号链接
print_info "创建符号链接..."
if ln -s "$SOURCE_SCRIPT" "$TARGET_PATH"; then
    print_success "安装成功！"
    echo ""
    print_info "现在可以在任何地方使用以下命令:"
    print_info "  $TARGET_NAME <git-url>"
    echo ""
    print_info "示例:"
    print_info "  $TARGET_NAME https://github.com/langgenius/dify"
    print_info "  $TARGET_NAME https://gitea.skyner.cn/org/suborg/repo"
    print_info "  $TARGET_NAME https://gitee.com/org/suborg/repo"
    echo ""
    
    # 如果创建了 ~/bin 且不在 PATH 中，给出提示
    if [ "$INSTALL_DIR" == "$HOME/bin" ] && [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
        print_warning "注意: $HOME/bin 可能不在您的 PATH 中"
        print_info "请运行以下命令或重启终端:"
        print_info "  export PATH=\"\$HOME/bin:\$PATH\""
        echo ""
        print_info "或者将以下内容添加到 ~/.zshrc:"
        print_info "  export PATH=\"\$HOME/bin:\$PATH\""
    fi
else
    print_error "创建符号链接失败"
    exit 1
fi
