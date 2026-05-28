#!/bin/bash
# 智能克隆 Git 仓库脚本
# 用法: ./clone-github-repo.sh <git-url>
# 示例: ./clone-github-repo.sh https://github.com/langgenius/dify

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/gitclone-config.json"
PROJECTS_DIR="$HOME/Documents/Projects"

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

# 读取配置文件
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        print_warning "配置文件不存在: $CONFIG_FILE，使用默认配置"
        return 1
    fi
    
    # 使用 python3 解析 JSON
    if command -v python3 &> /dev/null; then
        python3 -c "
import json
import sys
import os

try:
    with open(\"$CONFIG_FILE\", \"r\") as f:
        config = json.load(f)
    
    # 读取服务器映射
    server_mappings = config.get(\"server_mappings\", {})
    for host, dir_name in server_mappings.items():
        print(f\"SERVER_MAP:{host}:{dir_name}\")
    
    # 读取基础目录
    base_dir = config.get(\"base_dir\", \"~/Documents/Projects\")
    print(f\"BASE_DIR:{base_dir}\")
    
    # 读取编辑器列表
    editors = config.get(\"editors\", [])
    for i, editor in enumerate(editors):
        name = editor.get(\"name\", \"\")
        command = editor.get(\"command\", \"\")
        app_path = editor.get(\"app_path\", \"\")
        print(f\"EDITOR:{i}:{name}:{command}:{app_path}\")
        
except Exception as e:
    sys.exit(1)
" 2>/dev/null
    else
        print_warning "未找到 python3，无法读取配置文件，使用默认配置"
        return 1
    fi
}

# 获取服务器类型对应的目录名（从配置文件或默认值）
get_server_dir() {
    local host="$1"
    
    # 尝试从配置文件读取
    if [ -f "$CONFIG_FILE" ] && command -v python3 &> /dev/null; then
        local mapped_dir=$(python3 -c "
import json
import sys
try:
    with open(\"$CONFIG_FILE\", \"r\") as f:
        config = json.load(f)
    server_mappings = config.get(\"server_mappings\", {})
    print(server_mappings.get(\"$host\", \"\"))
except:
    pass
" 2>/dev/null)
        
        if [ -n "$mapped_dir" ]; then
            echo "$mapped_dir"
            return 0
        fi
    fi
    
    # 使用默认映射（作为备用，如果配置文件读取失败）
    case "$host" in
        github.com)
            echo "github"
            ;;
        gitea.skyner.cn)
            echo "gitea"
            ;;
        gitee.com)
            echo "gitee"
            ;;
        cnb.cool)
            echo "cnb"
            ;;
        *)
            # 对于未知服务器，使用主机名（去掉端口号）
            echo "${host%%:*}"
            ;;
    esac
}

# 获取基础目录（从配置文件或默认值）
get_base_dir() {
    if [ -f "$CONFIG_FILE" ] && command -v python3 &> /dev/null; then
        local base_dir=$(python3 -c "
import json
import os
try:
    with open(\"$CONFIG_FILE\", \"r\") as f:
        config = json.load(f)
    base_dir = config.get(\"base_dir\", \"~/Documents/Projects\")
    # 展开 ~
    base_dir = os.path.expanduser(base_dir)
    print(base_dir)
except:
    pass
" 2>/dev/null)
        
        if [ -n "$base_dir" ]; then
            echo "$base_dir"
            return 0
        fi
    fi
    
    # 默认值
    echo "$HOME/Documents/Projects"
}

# 查找项目的 README 文件
find_readme() {
    local project_dir="$1"
    local readme_files=("README.md" "README.rst" "README.txt" "README" "readme.md" "readme.txt")
    
    for readme in "${readme_files[@]}"; do
        if [ -f "$project_dir/$readme" ]; then
            echo "$readme"
            return 0
        fi
    done
    
    return 1
}

# 生成项目级别的目录树（只显示到项目目录，不深入项目内部）
generate_projects_tree() {
    local dir="$1"
    local prefix="$2"
    local is_last="$3"
    local base_dir="${4:-$PROJECTS_DIR}"
    
    # 检查目录是否存在
    if [ ! -d "$dir" ]; then
        return 0
    fi
    
    if [ -z "$prefix" ]; then
        prefix=""
        is_last="1"
    fi
    
    local name=$(basename "$dir")
    local display_name="$name"
    
    # 如果是根目录，显示完整路径的最后一部分
    if [ "$dir" == "$PROJECTS_DIR" ]; then
        display_name="Projects"
    fi
    
    # 如果这个目录包含 .git 或 .svn，说明是项目根目录，不再深入
    if [ -d "$dir/.git" ] || [ -d "$dir/.svn" ]; then
        # 获取项目信息
        local project_info=""
        local is_git=false
        local is_svn=false
        
        if [ -d "$dir/.git" ]; then
            is_git=true
        fi
        
        if [ -d "$dir/.svn" ]; then
            is_svn=true
        fi
        
        # 获取当前分支（仅 Git 项目）
        local current_branch=""
        if [ "$is_git" = true ]; then
            current_branch=$(cd "$dir" && git branch --show-current 2>/dev/null || echo "")
        fi
        
        # 获取文件夹大小（人类可读格式）
        local dir_size=""
        if command -v du &> /dev/null; then
            dir_size=$(du -sh "$dir" 2>/dev/null | cut -f1 || echo "")
        fi
        
        # 组装项目信息
        if [ "$is_git" = true ] && [ -n "$current_branch" ] && [ -n "$dir_size" ]; then
            project_info="[$current_branch, $dir_size]"
        elif [ "$is_git" = true ] && [ -n "$current_branch" ]; then
            project_info="[$current_branch]"
        elif [ "$is_svn" = true ] && [ -n "$dir_size" ]; then
            project_info="[SVN, $dir_size]"
        elif [ -n "$dir_size" ]; then
            project_info="[$dir_size]"
        elif [ "$is_svn" = true ]; then
            project_info="[SVN]"
        fi
        
        # 打印当前目录（项目）带信息
        if [ -n "$project_info" ]; then
            if [ "$is_last" == "1" ]; then
                echo "${prefix}└── $display_name $project_info"
            else
                echo "${prefix}├── $display_name $project_info"
            fi
        else
            if [ "$is_last" == "1" ]; then
                echo "${prefix}└── $display_name"
            else
                echo "${prefix}├── $display_name"
            fi
        fi
        return 0
    fi
    
    # 打印当前目录（非项目目录）
    if [ "$is_last" == "1" ]; then
        echo "${prefix}└── $display_name"
        local new_prefix="${prefix}    "
    else
        echo "${prefix}├── $display_name"
        local new_prefix="${prefix}│   "
    fi
    
    # 获取子目录（只显示目录，不显示文件）
    local items=()
    if [ -d "$dir" ] && [ -r "$dir" ]; then
        local temp_items_file="/tmp/gitclone_tree_items_$$.txt"
        ls -d "$dir"/*/ 2>/dev/null | sed "s|$dir/||" | sed 's|/$||' | sort > "$temp_items_file" 2>/dev/null || true
        
        if [ -f "$temp_items_file" ] && [ -s "$temp_items_file" ]; then
            while IFS= read -r item || [ -n "$item" ]; do
                [ -z "$item" ] && continue
                # 跳过 .git 和 .svn 目录本身（它们是隐藏目录）
                if [[ "$item" == ".git" ]] || [[ "$item" == ".svn" ]]; then
                    continue
                fi
                # 只显示目录
                if [ -d "$dir/$item" ]; then
                    items+=("$item")
                fi
            done < "$temp_items_file"
            rm -f "$temp_items_file" 2>/dev/null || true
        fi
    fi
    
    # 递归处理子目录
    local count=${#items[@]}
    local index=0
    for item in "${items[@]}"; do
        [ -z "$item" ] && continue
        index=$((index + 1))
        local is_last_item="0"
        if [ $index -eq $count ]; then
            is_last_item="1"
        fi
        
        if [ -d "$dir/$item" ] && [ -r "$dir/$item" ]; then
            generate_projects_tree "$dir/$item" "$new_prefix" "$is_last_item" "$base_dir" || true
        fi
    done
    
    return 0
}

# 生成项目目录说明文件
generate_projects_index() {
    # 临时禁用 set -e，避免因命令失败而退出
    set +e
    
    local projects_dir="$PROJECTS_DIR"
    local index_file="$projects_dir/README.md"
    
    if [ ! -d "$projects_dir" ]; then
        print_warning "项目目录不存在: $projects_dir"
        set -e
        return 1
    fi
    
    print_info "正在生成项目目录索引文件..."
    
    # 创建或清空索引文件
    cat > "$index_file" << EOF
# Projects 目录索引

> 自动生成的项目索引
> 
> 最后更新: $(date '+%Y-%m-%d %H:%M:%S')

## 📁 项目目录结构

\`\`\`
EOF

    # 生成项目级别的目录树（只显示到项目目录，不深入项目内部）
    generate_projects_tree "$projects_dir" "" "1" "$projects_dir" >> "$index_file" 2>/dev/null || true
    
    cat >> "$index_file" << EOF
\`\`\`

---

## 📝 说明

- 本文件由 \`gitclone\` 脚本自动生成和更新
- 每次克隆新仓库后会自动更新此文件
- 目录树只显示项目级别的结构，不深入项目内部
- 识别最顶层的 Git 仓库（.git）和 SVN 工作副本（.svn）
- 忽略子模块和依赖中的 .git 目录

## 🔧 手动更新

如果需要手动更新此文件，可以运行：

\`\`\`bash
# 刷新索引文件
gitclone --refresh
# 或
gitclone -r
# 或
gitclone --update-index
# 或
gitclone -u
\`\`\`

---

*最后更新: $(date '+%Y-%m-%d %H:%M:%S')*
EOF

    # 重新启用 set -e
    set -e
    
    print_success "项目目录索引文件已生成: $index_file"
}

# 打开仓库目录
open_repo() {
    local repo_dir="$1"
    
    if [ ! -d "$repo_dir" ]; then
        print_error "目录不存在: $repo_dir"
        return 1
    fi
    
    # 读取编辑器列表
    if [ ! -f "$CONFIG_FILE" ] || ! command -v python3 &> /dev/null; then
        print_warning "无法读取配置文件，使用默认编辑器列表"
        # 默认编辑器列表
        declare -a editors=(
            "Cursor:cursor:/Applications/Cursor.app"
            "VS Code:code:/Applications/Visual Studio Code.app"
            "IntelliJ IDEA:idea:/Applications/IntelliJ IDEA.app"
            "WebStorm:webstorm:/Applications/WebStorm.app"
            "TRAE:trae:/Applications/Trae CN.app"
        )
    else
        # 从配置文件读取编辑器列表
        editors_str=$(python3 -c "
import json
try:
    with open(\"$CONFIG_FILE\", \"r\") as f:
        config = json.load(f)
    editors = config.get(\"editors\", [])
    for editor in editors:
        name = editor.get(\"name\", \"\")
        command = editor.get(\"command\", \"\")
        app_path = editor.get(\"app_path\", \"\")
        print(f\"{name}:{command}:{app_path}\")
except:
    pass
" 2>/dev/null)
        
        # 转换为数组
        IFS=$'\n' read -d '' -r -a editors <<< "$editors_str" || true
    fi
    
    if [ ${#editors[@]} -eq 0 ]; then
        print_error "未找到可用的编辑器配置"
        return 1
    fi
    
    # 过滤可用的编辑器
    declare -a available_editors=()
    declare -a available_names=()
    declare -a available_commands=()
    
    for editor_info in "${editors[@]}"; do
        if [ -z "$editor_info" ]; then
            continue
        fi
        
        IFS=':' read -r name command app_path <<< "$editor_info"
        
        # 检查应用是否存在或命令是否可用
        local is_available=0
        if [ -n "$app_path" ] && [ -d "$app_path" ]; then
            is_available=1
        elif command -v "$command" &> /dev/null; then
            is_available=1
        fi
        
        if [ $is_available -eq 1 ]; then
            available_editors+=("$editor_info")
            available_names+=("$name")
            available_commands+=("$command")
        fi
    done
    
    if [ ${#available_editors[@]} -eq 0 ]; then
        print_warning "未找到可用的编辑器"
        print_info "尝试使用系统默认方式打开..."
        open "$repo_dir"
        return 0
    fi
    
    # 如果有优先编辑器，尝试直接使用
    # 显示编辑器选择菜单
    echo ""
    print_info "请选择打开方式:"
    echo ""
    for i in "${!available_names[@]}"; do
        echo "  $((i+1)). ${available_names[$i]}"
    done
    echo "  0. 取消"
    echo ""
    
    while true; do
        read -p "请输入选项 (0-${#available_names[@]}): " choice
        
        if [[ "$choice" == "0" ]]; then
            print_info "已取消打开"
            return 0
        fi
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#available_names[@]}" ]; then
            local selected_index=$((choice-1))
            local selected_command="${available_commands[$selected_index]}"
            local selected_name="${available_names[$selected_index]}"
            
            print_info "使用 $selected_name 打开仓库..."
            
            # 执行打开命令
            if command -v "$selected_command" &> /dev/null; then
                $selected_command "$repo_dir" &
                print_success "已使用 $selected_name 打开仓库"
            else
                # 尝试使用 open 命令打开应用
                IFS=':' read -r name cmd app_path <<< "${available_editors[$selected_index]}"
                if [ -n "$app_path" ] && [ -d "$app_path" ]; then
                    open -a "$app_path" "$repo_dir"
                    print_success "已使用 $selected_name 打开仓库"
                else
                    print_error "无法打开 $selected_name"
                    return 1
                fi
            fi
            return 0
        else
            print_error "无效的选项，请重新输入"
        fi
    done
}

# 解析 Git URL，提取服务器、组织路径和仓库名
parse_git_url() {
    local url="$1"
    local server=""
    local org_path=""
    local repo=""
    
    # 移除 .git 后缀（如果存在）
    url="${url%.git}"
    
    # 处理 HTTPS URL: https://github.com/org/suborg/repo
    if [[ "$url" =~ ^https://([^/]+)/(.+)$ ]]; then
        server="${BASH_REMATCH[1]}"
        local path="${BASH_REMATCH[2]}"
        
        # 分离组织路径和仓库名（最后一部分是仓库名）
        if [[ "$path" =~ ^(.+)/([^/]+)$ ]]; then
            org_path="${BASH_REMATCH[1]}"
            repo="${BASH_REMATCH[2]}"
        else
            print_error "URL 格式不正确，至少需要组织名和仓库名"
            return 1
        fi
    
    # 处理 SSH URL: git@github.com:org/suborg/repo
    elif [[ "$url" =~ ^git@([^:]+):(.+)$ ]]; then
        server="${BASH_REMATCH[1]}"
        local path="${BASH_REMATCH[2]}"
        
        # 分离组织路径和仓库名（最后一部分是仓库名）
        if [[ "$path" =~ ^(.+)/([^/]+)$ ]]; then
            org_path="${BASH_REMATCH[1]}"
            repo="${BASH_REMATCH[2]}"
        else
            print_error "URL 格式不正确，至少需要组织名和仓库名"
            return 1
        fi
    
    # 处理简化的 SSH URL: ssh://git@host/path
    elif [[ "$url" =~ ^ssh://git@([^/]+)/(.+)$ ]]; then
        server="${BASH_REMATCH[1]}"
        local path="${BASH_REMATCH[2]}"
        
        if [[ "$path" =~ ^(.+)/([^/]+)$ ]]; then
            org_path="${BASH_REMATCH[1]}"
            repo="${BASH_REMATCH[2]}"
        else
            print_error "URL 格式不正确，至少需要组织名和仓库名"
            return 1
        fi
    
    else
        print_error "无法解析 Git URL: $url"
        print_info "支持的格式:"
        print_info "  - https://github.com/org/repo"
        print_info "  - https://github.com/org/suborg/repo"
        print_info "  - https://github.com/org/suborg/repo.git"
        print_info "  - git@github.com:org/repo"
        print_info "  - git@github.com:org/suborg/repo"
        print_info "  - git@github.com:org/suborg/repo.git"
        return 1
    fi
    
    # 输出：服务器|组织路径|仓库名
    echo "$server|$org_path|$repo"
}

# 将 HTTPS URL 转换为 SSH URL
convert_to_ssh_url() {
    local https_url="$1"
    local ssh_url=""
    
    # 处理 GitHub HTTPS URL
    if [[ "$https_url" =~ ^https://github.com/(.+)$ ]]; then
        ssh_url="git@github.com:${BASH_REMATCH[1]}"
    # 处理其他 HTTPS URL
    elif [[ "$https_url" =~ ^https://([^/]+)/(.+)$ ]]; then
        local host="${BASH_REMATCH[1]}"
        local path="${BASH_REMATCH[2]}"
        ssh_url="git@${host}:${path}"
    else
        return 1
    fi
    
    echo "$ssh_url"
}

# 检测网络连通性（带测速）
check_connectivity() {
    local git_url="$1"
    local server=""
    local port=""
    local protocol=""
    
    # 从 URL 中提取服务器和协议
    if [[ "$git_url" =~ ^https://([^/]+) ]]; then
        server="${BASH_REMATCH[1]}"
        protocol="https"
        port="443"
    elif [[ "$git_url" =~ ^git@([^:]+) ]]; then
        server="${BASH_REMATCH[1]}"
        protocol="ssh"
        port="22"
    elif [[ "$git_url" =~ ^ssh://git@([^/]+) ]]; then
        server="${BASH_REMATCH[1]}"
        protocol="ssh"
        port="22"
    else
        print_warning "无法识别 URL 协议，跳过连通性检测"
        return 0
    fi
    
    # 处理带端口的服务器地址（如 host:port）
    if [[ "$server" =~ ^([^:]+):([0-9]+)$ ]]; then
        server="${BASH_REMATCH[1]}"
        port="${BASH_REMATCH[2]}"
    fi
    
    print_info "正在检测网络连通性: $server:$port ($protocol)..."
    
    # 检查 Git 代理配置
    local git_http_proxy=$(git config --global --get http.proxy 2>/dev/null || echo "")
    local git_https_proxy=$(git config --global --get https.proxy 2>/dev/null || echo "")
    if [ -n "$git_http_proxy" ] || [ -n "$git_https_proxy" ]; then
        print_info "  检测到 Git 代理配置:"
        [ -n "$git_http_proxy" ] && print_info "    HTTP 代理: $git_http_proxy"
        [ -n "$git_https_proxy" ] && print_info "    HTTPS 代理: $git_https_proxy"
    fi
    
    local can_connect=0
    local ping_latency=""
    local tcp_latency=""
    local git_test_success=0
    
    # 1. 先尝试 ping 测试延迟（如果可用且未被禁用）
    if command -v ping &> /dev/null; then
        # macOS 的 ping 使用 -c 1 表示只 ping 一次，-W 设置超时（毫秒）
        # 提取时间信息：time=XX.XXX ms
        local ping_result=$(ping -c 1 -W 3000 "$server" 2>&1)
        if [ $? -eq 0 ]; then
            # 提取延迟时间（macOS ping 格式：time=XX.XXX ms）
            ping_latency=$(echo "$ping_result" | grep -oE "time=[0-9.]+" | head -1 | cut -d= -f2)
            if [ -n "$ping_latency" ]; then
                print_info "  Ping 延迟: ${ping_latency} ms"
            fi
        fi
    fi
    
    # 2. 测试 TCP 端口连接并测量延迟
    if command -v nc &> /dev/null; then
        # 使用 date 命令测量 nc 连接时间（macOS date 支持 %s.%N）
        local start_time=$(date +%s.%N 2>/dev/null)
        if [ -z "$start_time" ]; then
            # 如果不支持纳秒，使用秒级精度
            start_time=$(date +%s)
        fi
        
        # 使用 nc -zv 进行检测（macOS 和 Linux 都支持）
        # -z: 只扫描，不发送数据
        # -v: 详细输出
        # -w: 超时时间（秒），macOS 使用 -w，Linux 可能使用 -G
        local nc_output=""
        local nc_exit_code=1
        
        # 尝试 macOS 风格的 nc（使用 -w 超时）
        nc_output=$(nc -zv -w 3 "$server" "$port" 2>&1)
        nc_exit_code=$?
        
        # 如果失败，尝试 Linux 风格的 nc（使用 -G 超时）
        if [ $nc_exit_code -ne 0 ]; then
            nc_output=$(nc -zv -G 3 "$server" "$port" 2>&1)
            nc_exit_code=$?
        fi
        
        # 检查是否连接成功（通过退出码和输出内容）
        # macOS nc 输出格式: "Connection to github.com port 443 [tcp/https] succeeded!"
        # Linux nc 输出格式可能不同，但都包含 "succeeded" 或 "open"
        if [ $nc_exit_code -eq 0 ] || echo "$nc_output" | grep -qiE "succeeded|open|Connection.*succeeded"; then
            local end_time=$(date +%s.%N 2>/dev/null)
            if [ -z "$end_time" ]; then
                end_time=$(date +%s)
            fi
            
            # 计算延迟（毫秒），使用 awk 计算（macOS 自带 awk）
            if command -v awk &> /dev/null; then
                tcp_latency=$(awk -v start="$start_time" -v end="$end_time" 'BEGIN {
                    diff = (end - start) * 1000
                    if (diff < 0) diff = 0
                    printf "%.0f", diff
                }' 2>/dev/null)
            fi
            
            if [ -n "$tcp_latency" ] && [ "$tcp_latency" != "0" ] && [ "$tcp_latency" != "" ]; then
                print_info "  TCP 连接延迟: ${tcp_latency} ms"
            fi
            can_connect=1
        fi
    # 如果没有 nc，尝试使用 bash 内置的 TCP 连接（带超时）
    elif command -v bash &> /dev/null; then
        local start_time=$(date +%s.%N 2>/dev/null || date +%s)
        (
            bash -c "echo > /dev/tcp/$server/$port" 2>/dev/null
        ) &
        local pid=$!
        sleep 3
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
        else
            local end_time=$(date +%s.%N 2>/dev/null || date +%s)
            if command -v awk &> /dev/null; then
                tcp_latency=$(awk -v start="$start_time" -v end="$end_time" 'BEGIN {
                    diff = (end - start) * 1000
                    if (diff < 0) diff = 0
                    printf "%.0f", diff
                }' 2>/dev/null)
            fi
            if [ -n "$tcp_latency" ] && [ "$tcp_latency" != "0" ] && [ "$tcp_latency" != "" ]; then
                print_info "  TCP 连接延迟: ${tcp_latency} ms"
            fi
            wait "$pid" 2>/dev/null &&             can_connect=1
        fi
    fi
    
    # 3. 使用 git ls-remote 测试实际 Git 连接（最准确的方式）
    if [ $can_connect -eq 0 ] && [[ "$git_url" =~ ^https:// ]]; then
        print_info "  使用 Git 测试连接（最准确的方式）..."
        # 只测试连接，不实际拉取数据（使用 --heads 限制输出）
        # macOS 可能没有 timeout 命令，使用后台进程实现超时
        local git_test_result=""
        (
            git ls-remote --heads "$git_url" > /dev/null 2>&1
            echo $? > /tmp/gitclone_git_test_$$.txt
        ) &
        local git_test_pid=$!
        sleep 5
        if kill -0 "$git_test_pid" 2>/dev/null; then
            kill "$git_test_pid" 2>/dev/null
            print_info "  ⚠ Git 连接测试超时"
        else
            wait "$git_test_pid" 2>/dev/null
            local git_test_exit_code=$(cat /tmp/gitclone_git_test_$$.txt 2>/dev/null || echo "1")
            rm -f /tmp/gitclone_git_test_$$.txt 2>/dev/null
            
            if [ "$git_test_exit_code" = "0" ]; then
                git_test_success=1
                can_connect=1
                print_info "  ✓ Git 连接测试成功"
            else
                # 如果 git ls-remote 失败，可能是认证问题，但连接可能正常
                # 检查错误类型（重新运行一次获取错误信息）
                local git_error=$(git ls-remote --heads "$git_url" 2>&1 | head -3)
                if echo "$git_error" | grep -qi "timeout\|connection\|refused\|dial tcp"; then
                    print_info "  ✗ Git 连接测试失败（网络问题）"
                else
                    # 可能是认证问题，但连接本身可能正常
                    print_info "  ⚠ Git 连接测试未通过（可能是认证问题，但连接可能正常）"
                fi
            fi
        fi
    fi
    
    # 4. 评估连接质量
    if [ $can_connect -eq 1 ]; then
        local quality=""
        local latency_value=""
        
        # 优先使用 ping 延迟，如果没有则使用 TCP 延迟
        if [ -n "$ping_latency" ]; then
            # 提取整数部分用于比较
            latency_value=$(echo "$ping_latency" | awk -F. '{print $1}' | awk '{print int($1)}')
        elif [ -n "$tcp_latency" ]; then
            latency_value=$(echo "$tcp_latency" | awk '{print int($1)}')
        fi
        
        if [ -n "$latency_value" ] && [ "$latency_value" != "" ] && [ "$latency_value" != "0" ]; then
            # 使用 awk 进行数值比较（支持小数）
            if command -v awk &> /dev/null; then
                quality=$(awk -v lat="$latency_value" 'BEGIN {
                    if (lat < 50) print "优秀"
                    else if (lat < 100) print "良好"
                    else if (lat < 200) print "一般"
                    else print "较慢"
                }')
            else
                # 降级到整数比较
                if [ "$latency_value" -lt 50 ]; then
                    quality="优秀"
                elif [ "$latency_value" -lt 100 ]; then
                    quality="良好"
                elif [ "$latency_value" -lt 200 ]; then
                    quality="一般"
                else
                    quality="较慢"
                fi
            fi
            print_success "网络连通性检测通过: $server:$port (连接质量: $quality)"
        else
            print_success "网络连通性检测通过: $server:$port"
        fi
        
        # 显示测速摘要
        if [ -n "$ping_latency" ] || [ -n "$tcp_latency" ]; then
            echo ""
            echo -e "  ${GREEN}📊 测速信息:${NC}"
            if [ -n "$ping_latency" ]; then
                echo -e "     ${BLUE}•${NC} ICMP Ping 延迟: ${GREEN}${ping_latency} ms${NC}"
            fi
            if [ -n "$tcp_latency" ]; then
                echo -e "     ${BLUE}•${NC} TCP 连接延迟: ${GREEN}${tcp_latency} ms${NC}"
            fi
        fi
        
        return 0
    else
        # Ping 成功但 TCP 连接失败的特殊情况
        if [ -n "$ping_latency" ]; then
            print_warning "端口检测未通过，但网络基本连通"
            echo ""
            print_info "诊断信息："
            print_info "  ✓ ICMP Ping 成功（延迟: ${ping_latency} ms）"
            print_info "  ✗ TCP 端口 $port 检测失败"
            
            # 如果 Git 测试成功，说明实际连接是正常的
            if [ $git_test_success -eq 1 ]; then
                echo ""
                print_success "但 Git 连接测试成功，可以正常使用！"
                print_info "端口检测可能过于严格，实际 Git 操作应该可以正常进行"
                can_connect=1
            else
                echo ""
                print_warning "可能的原因："
                print_warning "  1. 防火墙或网络策略阻止了 $port 端口"
                print_warning "  2. 需要 VPN 或代理才能访问该端口"
                print_warning "  3. 网络运营商可能限制了该端口"
                print_warning "  4. GitHub Desktop 可能使用了不同的连接方式"
                echo ""
                
                # 针对 GitHub HTTPS 的特殊处理
                if [[ "$server" == "github.com" ]] && [[ "$port" == "443" ]]; then
                print_info "针对 GitHub HTTPS 的解决方案："
                echo ""
                
                # 检查是否可以使用 SSH
                print_info "方案 1: 使用 SSH 方式（推荐，端口 22 通常更稳定）"
                if [[ "$git_url" =~ ^https://github.com ]]; then
                    local ssh_url=$(convert_to_ssh_url "$git_url")
                    if [ -n "$ssh_url" ]; then
                        print_info "  可以尝试使用 SSH URL:"
                        print_info "    $ssh_url"
                        echo ""
                        read -p "是否立即尝试使用 SSH 方式？(Y/n): " try_ssh_now
                        if [[ ! "$try_ssh_now" =~ ^[Nn]$ ]]; then
                            print_info "正在检测 SSH 端口连通性..."
                            if command -v nc &> /dev/null; then
                                if nc -z -G 3 "$server" 22 2>/dev/null; then
                                    print_success "SSH 端口 (22) 可以连接！"
                                    echo ""
                                    print_info "建议使用以下命令："
                                    print_info "  gitclone $ssh_url"
                                    echo ""
                                    read -p "是否现在使用 SSH 方式克隆？(Y/n): " use_ssh
                                    if [[ ! "$use_ssh" =~ ^[Nn]$ ]]; then
                                        # 返回特殊状态，让主函数知道要使用 SSH
                                        # 使用环境变量传递信息（因为函数返回值有限）
                                        export GITCLONE_USE_SSH_URL="$ssh_url"
                                        return 0  # 返回成功，让主函数继续执行
                                    fi
                                else
                                    print_warning "SSH 端口 (22) 也无法连接"
                                fi
                            fi
                        fi
                    fi
                fi
                
                echo ""
                print_info "方案 2: 配置代理"
                print_info "  如果使用代理，配置 Git 代理："
                print_info "    git config --global http.proxy http://proxy.example.com:8080"
                print_info "    git config --global https.proxy https://proxy.example.com:8080"
                echo ""
                print_info "方案 3: 使用 GitHub 镜像站点"
                print_info "  某些地区可能有 GitHub 镜像，可以尝试："
                print_info "    - 使用 VPN 服务"
                print_info "    - 使用 GitHub 代理服务"
                echo ""
                print_info "方案 4: 检查网络设置"
                print_info "  运行以下命令检查网络："
                print_info "    curl -I https://github.com"
                print_info "    telnet github.com 443"
                fi
            fi
            
            # 如果 Git 测试也失败，询问是否继续
            if [ $git_test_success -eq 0 ]; then
                echo ""
                print_info "提示：如果 GitHub Desktop 可以正常拉取，说明网络连接是正常的"
                print_info "端口检测可能不够准确，实际 Git 操作可能可以成功"
                echo ""
                read -p "是否继续尝试克隆？(Y/n): " continue_confirm
                if [[ "$continue_confirm" =~ ^[Nn]$ ]]; then
                    print_info "操作已取消"
                    return 1
                else
                    print_info "继续执行克隆操作..."
                    return 0
                fi
            else
                # Git 测试成功，可以继续
                return 0
            fi
        else
            # 常规错误处理（没有 ping 延迟的情况）
            print_warning "网络检测未通过"
            print_info "可能的原因："
            print_info "  1. 网络连接暂时不稳定"
            print_info "  2. 服务器暂时不可用"
            print_info "  3. 检测方式可能不够准确"
            echo ""
            print_info "提示：如果 GitHub Desktop 可以正常拉取，说明网络连接是正常的"
            print_info "检测可能过于严格，实际 Git 操作可能可以成功"
            echo ""
            read -p "是否继续尝试克隆？(Y/n): " continue_confirm
            if [[ "$continue_confirm" =~ ^[Nn]$ ]]; then
                print_info "操作已取消"
                return 1
            else
                print_info "继续执行克隆操作..."
                return 0
            fi
        fi
    fi
}

# 显示帮助信息
show_help() {
    cat << EOF
用法: $0 <git-url>

智能克隆 Git 仓库到配置的目录结构中

支持的服务器:
  - github.com      -> ~/Documents/Projects/github/
  - gitea.skyner.cn -> ~/Documents/Projects/gitea/
  - gitee.com       -> ~/Documents/Projects/gitee/
  - 其他服务器      -> ~/Documents/Projects/{主机名}/

参数:
  git-url    Git 仓库的 URL

支持的 URL 格式:
  - https://github.com/langgenius/dify
  - https://github.com/org/suborg/repo
  - https://gitea.skyner.cn/org/suborg/repo
  - https://gitee.com/org/suborg/repo
  - git@github.com:org/suborg/repo
  - git@gitea.skyner.cn:org/suborg/repo
  - git@gitee.com:org/suborg/repo

示例:
  $0 https://github.com/langgenius/dify
  $0 https://github.com/org/suborg/repo
  $0 git@github.com:langgenius/dify.git
  $0 https://gitea.skyner.cn/org/suborg/repo

注意:
  - 支持多层组织结构，最后一部分是仓库名
  - 例如: github.com/org/suborg/repo -> github/org/suborg/repo
  - 配置文件: $CONFIG_FILE
  - 克隆完成后可选择立即打开仓库
  - 每次克隆后会自动生成/更新项目目录索引文件 (README.md)

选项:
  -h, --help         显示此帮助信息
  -u, --update-index 手动更新项目目录索引文件
  -r, --refresh      刷新项目目录索引文件（同 --update-index）
EOF
}

# 主函数
main() {
    echo "=========================================="
    echo "    智能克隆 Git 仓库工具"
    echo "=========================================="
    echo ""
    
    # 检查参数
    if [ $# -eq 0 ]; then
        print_error "请提供 Git URL"
        echo ""
        show_help
        exit 1
    fi
    
    # 处理帮助选项
    if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        show_help
        exit 0
    fi
    
    # 处理更新索引选项
    if [[ "$1" == "--update-index" ]] || [[ "$1" == "-u" ]] || [[ "$1" == "--refresh" ]] || [[ "$1" == "-r" ]]; then
        generate_projects_index
        exit 0
    fi
    
    local git_url="$1"
    print_info "Git URL: $git_url"
    
    # 解析 URL
    local parsed=$(parse_git_url "$git_url")
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    local server=$(echo "$parsed" | cut -d'|' -f1)
    local org_path=$(echo "$parsed" | cut -d'|' -f2)
    local repo=$(echo "$parsed" | cut -d'|' -f3)
    
    # 获取服务器对应的目录名
    local server_dir=$(get_server_dir "$server")
    
    # 获取基础目录
    local base_dir=$(get_base_dir)
    
    print_info "服务器: $server"
    print_info "目录类型: $server_dir"
    print_info "组织路径: $org_path"
    print_info "仓库名: $repo"
    echo ""
    
    # 设置目标目录
    local org_dir="$base_dir/$server_dir/$org_path"
    local repo_dir="$org_dir/$repo"
    
    # 检测网络连通性（在克隆之前）
    # 清除之前可能设置的 SSH URL
    unset GITCLONE_USE_SSH_URL
    
    if ! check_connectivity "$git_url"; then
        # 检查是否建议使用 SSH
        if [ -n "$GITCLONE_USE_SSH_URL" ]; then
            echo ""
            print_info "正在使用建议的 SSH URL 进行克隆..."
            git_url="$GITCLONE_USE_SSH_URL"
            
            # 重新解析 URL（因为协议改变了）
            local parsed=$(parse_git_url "$git_url")
            if [ $? -ne 0 ]; then
                exit 1
            fi
            
            server=$(echo "$parsed" | cut -d'|' -f1)
            org_path=$(echo "$parsed" | cut -d'|' -f2)
            repo=$(echo "$parsed" | cut -d'|' -f3)
            
            # 重新获取服务器对应的目录名
            server_dir=$(get_server_dir "$server")
            
            # 重新设置目标目录
            org_dir="$base_dir/$server_dir/$org_path"
            repo_dir="$org_dir/$repo"
            
            echo ""
        else
            exit 1
        fi
    fi
    echo ""
    
    # 检查仓库是否已存在
    if [ -d "$repo_dir" ]; then
        # 检查是否是 Git 仓库
        if [ -d "$repo_dir/.git" ]; then
            print_info "仓库已存在: $repo_dir"
            print_info "检测到是 Git 仓库，将执行更新操作..."
            echo ""
            
            # 进入仓库目录并更新
            cd "$repo_dir"
            
            # 获取当前分支
            local current_branch=$(git branch --show-current 2>/dev/null || echo "main")
            print_info "当前分支: $current_branch"
            
            # 执行 fetch
            print_info "正在获取最新更改..."
            if git fetch origin 2>&1; then
                print_success "获取成功"
            else
                print_warning "获取失败，但继续尝试更新"
            fi
            
            # 检查是否有更新
            local behind=$(git rev-list --count HEAD..origin/$current_branch 2>/dev/null || echo "0")
            if [ "$behind" != "0" ] && [ "$behind" != "" ]; then
                print_info "发现 $behind 个新提交，正在更新..."
                if git pull origin "$current_branch" 2>&1; then
                    print_success "更新成功！"
                else
                    print_warning "更新失败，但仓库已是最新状态"
                fi
            else
                print_info "仓库已是最新状态"
            fi
            
            # 返回原目录
            cd - > /dev/null
            
            # 生成/更新项目目录索引
            echo ""
            generate_projects_index
            
            # 询问是否立即打开
            echo ""
            read -p "是否立即打开仓库？(Y/n): " open_confirm
            if [[ ! "$open_confirm" =~ ^[Nn]$ ]]; then
                open_repo "$repo_dir"
            fi
            
            exit 0
        else
            # 不是 Git 仓库，询问是否覆盖
            print_warning "目录已存在但不是 Git 仓库: $repo_dir"
            read -p "是否继续？这将覆盖现有目录 (y/N): " confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                print_info "操作已取消"
                exit 0
            fi
            print_info "删除现有目录..."
            rm -rf "$repo_dir"
        fi
    fi
    
    # 创建组织目录（如果不存在）
    if [ ! -d "$org_dir" ]; then
        print_info "创建组织目录: $org_dir"
        mkdir -p "$org_dir"
    else
        print_info "组织目录已存在: $org_dir"
    fi
    
    echo ""
    print_info "开始克隆仓库..."
    print_info "目标目录: $repo_dir"
    echo ""
    
    # 执行 git clone（带重试机制和错误处理）
    set +e
    local max_retries=3
    local retry_count=0
    local clone_exit_code=1
    local temp_output="/tmp/gitclone_output_$$.txt"
    
    while [ $retry_count -lt $max_retries ]; do
        if [ $retry_count -gt 0 ]; then
            print_warning "克隆失败，正在重试 ($retry_count/$max_retries)..."
            echo ""
            # 如果目录已部分创建，先清理
            if [ -d "$repo_dir" ]; then
                rm -rf "$repo_dir"
            fi
        fi
        
        # 配置 Git 以增加缓冲区大小和超时时间
        GIT_HTTP_LOW_SPEED_LIMIT=1000
        GIT_HTTP_LOW_SPEED_TIME=300
        GIT_HTTP_POST_BUFFER=524288000
        
        # 执行 git clone（确保实时显示进度）
        # 使用 --progress 选项显示克隆进度
        # 使用 tee 同时输出到终端和文件，确保实时显示
        git -c http.postBuffer=524288000 -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=300 clone --progress "$git_url" "$repo_dir" 2>&1 | tee "$temp_output"
        clone_exit_code=${PIPESTATUS[0]}
        
        if [ $clone_exit_code -eq 0 ]; then
            break
        fi
        
        retry_count=$((retry_count + 1))
        
        # 如果不是最后一次重试，等待一下再继续
        if [ $retry_count -lt $max_retries ]; then
            sleep 2
        fi
    done
    
    set -e
    
    # 检查克隆结果
    if [ $clone_exit_code -eq 0 ]; then
        echo ""
        print_success "仓库克隆成功！"
        print_info "位置: $repo_dir"
        
        # 检查是否有 git-lfs 警告
        if grep -q "git-lfs.*command not found" "$temp_output" 2>/dev/null; then
            print_warning "检测到 git-lfs 未安装，某些大文件可能未正确下载"
            print_info "如需安装 git-lfs，请运行: brew install git-lfs"
        fi
        
        # 生成/更新项目目录索引
        echo ""
        generate_projects_index
        
        # 询问是否立即打开
        echo ""
        read -p "是否立即打开仓库？(Y/n): " open_confirm
        if [[ ! "$open_confirm" =~ ^[Nn]$ ]]; then
            open_repo "$repo_dir"
        fi
    else
        # 检查是否是 git-lfs 导致的失败
        if grep -q "git-lfs.*command not found" "$temp_output" 2>/dev/null; then
            print_warning "克隆过程中 git-lfs 未找到，但仓库可能已部分克隆"
            print_info "位置: $repo_dir"
            print_info "您可以尝试在仓库目录中运行: git restore --source=HEAD :/"
            print_info "或安装 git-lfs: brew install git-lfs"
            
            # 即使有 git-lfs 错误，如果目录存在，也继续处理
            if [ -d "$repo_dir" ] && [ -d "$repo_dir/.git" ]; then
                echo ""
                print_warning "仓库目录已创建，但 checkout 可能不完整"
                read -p "是否继续处理（生成索引等）？(y/N): " continue_confirm
                if [[ "$continue_confirm" =~ ^[Yy]$ ]]; then
                    generate_projects_index
                    read -p "是否立即打开仓库？(Y/n): " open_confirm
                    if [[ ! "$open_confirm" =~ ^[Nn]$ ]]; then
                        open_repo "$repo_dir"
                    fi
                fi
            else
                print_error "克隆失败"
                print_info "已重试 $max_retries 次，仍然失败"
                print_info "可能的原因："
                print_info "  1. 网络连接不稳定"
                print_info "  2. 仓库过大，需要更长时间"
                print_info "  3. 服务器暂时不可用"
                print_info ""
                print_info "建议："
                print_info "  1. 检查网络连接"
                print_info "  2. 稍后重试"
                print_info "  3. 如果仓库很大，可以尝试浅克隆: git clone --depth 1 $git_url"
                rm -f "$temp_output"
                exit 1
            fi
        else
            # 网络错误或其他错误
            print_error "克隆失败（已重试 $max_retries 次）"
            echo ""
            print_info "错误信息："
            grep -i "error\|fatal\|失败\|RPC\|Connection\|timeout\|authenticate" "$temp_output" 2>/dev/null | head -5 || tail -5 "$temp_output" 2>/dev/null
            echo ""
            
            # 检测特定错误类型并提供针对性建议
            local error_detected=0
            
            # 检测 GitHub 连接超时错误
            if grep -qi "dial tcp.*i/o timeout\|connection.*timeout\|failed to authenticate.*web browser" "$temp_output" 2>/dev/null; then
                error_detected=1
                print_warning "检测到 GitHub 连接超时或认证问题"
                echo ""
                print_info "可能的原因："
                print_info "  1. 网络连接不稳定或防火墙阻止"
                print_info "  2. GitHub 服务器暂时不可用或被限制访问"
                print_info "  3. 需要 VPN 或代理才能访问 GitHub"
                print_info "  4. DNS 解析问题"
                echo ""
                
                # 如果使用的是 HTTPS，询问是否尝试 SSH
                if [[ "$git_url" =~ ^https:// ]]; then
                    local ssh_url=$(convert_to_ssh_url "$git_url")
                    if [ -n "$ssh_url" ]; then
                        print_info "检测到您使用的是 HTTPS 方式，SSH 方式可能更稳定"
                        echo ""
                        read -p "是否尝试使用 SSH 方式重新克隆？(Y/n): " try_ssh
                        if [[ ! "$try_ssh" =~ ^[Nn]$ ]]; then
                            print_info "正在尝试使用 SSH 方式克隆: $ssh_url"
                            echo ""
                            
                            # 清理之前的失败尝试
                            if [ -d "$repo_dir" ]; then
                                rm -rf "$repo_dir"
                            fi
                            
                            # 使用 SSH URL 重新克隆
                            set +e
                            git clone --progress "$ssh_url" "$repo_dir" 2>&1 | tee "$temp_output"
                            local ssh_clone_exit_code=${PIPESTATUS[0]}
                            set -e
                            
                            if [ $ssh_clone_exit_code -eq 0 ]; then
                                echo ""
                                print_success "使用 SSH 方式克隆成功！"
                                print_info "位置: $repo_dir"
                                
                                # 生成/更新项目目录索引
                                echo ""
                                generate_projects_index
                                
                                # 询问是否立即打开
                                echo ""
                                read -p "是否立即打开仓库？(Y/n): " open_confirm
                                if [[ ! "$open_confirm" =~ ^[Nn]$ ]]; then
                                    open_repo "$repo_dir"
                                fi
                                
                                rm -f "$temp_output"
                                exit 0
                            else
                                print_warning "SSH 方式也失败了，可能的原因："
                                print_info "  1. 未配置 SSH 密钥"
                                print_info "  2. SSH 密钥未添加到 GitHub"
                                print_info "  3. 网络问题仍然存在"
                                echo ""
                                print_info "配置 SSH 密钥的方法："
                                print_info "  1. 生成 SSH 密钥: ssh-keygen -t ed25519 -C \"your_email@example.com\""
                                print_info "  2. 添加到 ssh-agent: ssh-add ~/.ssh/id_ed25519"
                                print_info "  3. 添加到 GitHub: https://github.com/settings/keys"
                                echo ""
                            fi
                        fi
                    fi
                fi
                
                print_info "其他解决方案："
                
                print_info "  2. 检查网络连接和 DNS："
                print_info "     ping github.com"
                print_info "     nslookup github.com"
                echo ""
                print_info "  3. 如果使用代理，配置 Git 代理："
                print_info "     git config --global http.proxy http://proxy.example.com:8080"
                print_info "     git config --global https.proxy https://proxy.example.com:8080"
                echo ""
                print_info "  4. 尝试使用 GitHub 镜像站点（如果可用）"
                echo ""
            fi
            
            # 检测认证失败错误
            if grep -qi "failed to authenticate\|authentication failed\|unauthorized" "$temp_output" 2>/dev/null; then
                error_detected=1
                print_warning "检测到认证失败"
                echo ""
                print_info "解决方案："
                if [[ "$git_url" =~ ^https://github.com ]]; then
                    print_info "  1. GitHub 已停止支持密码认证，请使用以下方式之一："
                    print_info "     - 使用 SSH 密钥（推荐）："
                    print_info "       gitclone git@github.com:org/repo.git"
                    print_info "     - 使用 Personal Access Token (PAT)"
                    print_info "     - 使用 GitHub CLI: gh auth login"
                    echo ""
                fi
            fi
            
            # 如果没有检测到特定错误，显示通用建议
            if [ $error_detected -eq 0 ]; then
                print_info "可能的原因："
                print_info "  1. 网络连接不稳定或中断"
                print_info "  2. 仓库过大，传输超时"
                print_info "  3. 服务器暂时不可用"
                print_info ""
                print_info "建议："
                print_info "  1. 检查网络连接后重试"
                print_info "  2. 如果仓库很大，可以尝试浅克隆:"
                print_info "     git clone --depth 1 $git_url $repo_dir"
                print_info "  3. 或者手动克隆后运行: gitclone --refresh"
            fi
            
            # 如果目录已部分创建，询问是否保留
            if [ -d "$repo_dir" ] && [ -d "$repo_dir/.git" ]; then
                echo ""
                print_warning "检测到部分克隆的目录: $repo_dir"
                read -p "是否保留并尝试恢复？(y/N): " keep_confirm
                if [[ "$keep_confirm" =~ ^[Yy]$ ]]; then
                    print_info "您可以尝试在目录中运行:"
                    print_info "  cd $repo_dir"
                    print_info "  git fetch --all"
                    print_info "  git reset --hard origin/HEAD"
                else
                    print_info "正在清理部分克隆的目录..."
                    rm -rf "$repo_dir"
                fi
            fi
            
            rm -f "$temp_output"
            exit 1
        fi
    fi
    
    # 清理临时文件
    rm -f "$temp_output"
}

# 运行主函数
main "$@"
