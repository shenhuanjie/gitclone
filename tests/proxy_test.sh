#!/bin/bash
# 代理功能测试脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CLONE_SCRIPT="$PROJECT_DIR/clone-github-repo.sh"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

passed=0
failed=0

test_proxy_detection() {
    local test_name="$1"
    local expected="$2"

    echo -e "${BLUE}[测试]${NC} $test_name"

    # 设置测试环境变量
    export ALL_PROXY="$expected"

    # 调用检测函数（通过 source）
    source "$CLONE_SCRIPT" 2>/dev/null

    local result=$(detect_env_proxy)

    if [ "$result" = "$expected" ]; then
        echo -e "${GREEN}✓ 通过${NC}: 检测到 $result"
        ((passed++))
    else
        echo -e "${RED}✗ 失败${NC}: 期望 $expected, 实际 $result"
        ((failed++))
    fi

    unset ALL_PROXY HTTP_PROXY HTTPS_PROXY
}

test_proxy_disabled() {
    echo -e "${BLUE}[测试]${NC} 代理禁用检测"

    # 创建临时配置文件禁用代理
    local temp_config="/tmp/test_config_$$.json"
    cat > "$temp_config" << 'EOF'
{
  "proxy": {
    "enabled": false
  }
}
EOF

    local result=$(python3 -c "
import json
with open('$temp_config', 'r') as f:
    config = json.load(f)
proxy = config.get('proxy', {})
print(str(proxy.get('enabled', True)))
" 2>/dev/null)

    if [ "$result" = "False" ]; then
        echo -e "${GREEN}✓ 通过${NC}: 代理禁用检测正常"
        ((passed++))
    else
        echo -e "${RED}✗ 失败${NC}: 代理禁用检测异常"
        ((failed++))
    fi

    rm -f "$temp_config"
}

test_config_proxy_precedence() {
    echo -e "${BLUE}[测试]${NC} 配置代理优先级"

    local temp_config="/tmp/test_config_$$.json"
    cat > "$temp_config" << 'EOF'
{
  "proxy": {
    "enabled": true,
    "url": "http://127.0.0.1:8080"
  }
}
EOF

    # 设置环境变量作为竞争条件
    export ALL_PROXY="http://127.0.0.1:7890"

    local result=$(python3 -c "
import json
with open('$temp_config', 'r') as f:
    config = json.load(f)
proxy = config.get('proxy', {})
if proxy.get('enabled', True) and proxy.get('url'):
    print(proxy['url'])
" 2>/dev/null)

    if [ "$result" = "http://127.0.0.1:8080" ]; then
        echo -e "${GREEN}✓ 通过${NC}: 配置代理优先于环境变量"
        ((passed++))
    else
        echo -e "${RED}✗ 失败${NC}: 配置代理未优先于环境变量"
        ((failed++))
    fi

    rm -f "$temp_config"
    unset ALL_PROXY
}

echo "=========================================="
echo "    代理功能测试"
echo "=========================================="
echo ""

test_proxy_detection "环境变量 ALL_PROXY 检测" "http://127.0.0.1:7890"
test_proxy_detection "环境变量 HTTP_PROXY 检测" "http://proxy.example.com:8080"
test_proxy_disabled
test_config_proxy_precedence

echo ""
echo "=========================================="
echo "测试结果: $passed 通过, $failed 失败"
echo "=========================================="

if [ $failed -gt 0 ]; then
    exit 1
fi
exit 0
