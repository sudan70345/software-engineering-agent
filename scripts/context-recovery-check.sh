#!/bin/bash
# 上下文恢复自检脚本
# 用途：会话恢复时快速检查必要上下文是否加载

set -e

COLOR_GREEN="\033[0;32m"
COLOR_RED="\033[0;31m"
COLOR_YELLOW="\033[1;33m"
COLOR_RESET="\033[0m"

# 检查项计数器
PASSED=0
FAILED=0
WARNINGS=0

check_item() {
    local label="$1"
    local condition="$2"

    if eval "$condition"; then
        echo -e "${COLOR_GREEN}✅${COLOR_RESET} $label"
        ((PASSED++))
        return 0
    else
        echo -e "${COLOR_RED}❌${COLOR_RESET} $label"
        ((FAILED++))
        return 1
    fi
}

warn_item() {
    local label="$1"
    echo -e "${COLOR_YELLOW}⚠️${COLOR_RESET} $label"
    ((WARNINGS++))
}

echo "🔍 开始上下文恢复自检..."
echo ""

# R1: 项目名是否明确
echo "【R1】项目名与系统目录"
if [ -d "document" ]; then
    PROJECTS=$(ls -d document/*/ 2>/dev/null | wc -l)
    if [ "$PROJECTS" -gt 0 ]; then
        check_item "document/ 目录存在且包含项目" "[ $PROJECTS -gt 0 ]"
        echo "   发现 $PROJECTS 个项目"
    else
        check_item "document/ 目录存在且包含项目" "false"
    fi
else
    check_item "document/ 目录存在" "false"
fi
echo ""

# R2: 项目级文件检查
echo "【R2】项目级文件检查"
LATEST_PROJECT=$(ls -td document/*/ 2>/dev/null | head -1)
if [ -n "$LATEST_PROJECT" ]; then
    PROJECT_NAME=$(basename "$LATEST_PROJECT")
    check_item "项目级产品摘要.md 存在" "[ -f '${LATEST_PROJECT}项目级产品摘要.md' ]"
    check_item "通用异常处理.md 存在" "[ -f '${LATEST_PROJECT}通用异常处理.md' ]"
    check_item "通用校验规则.md 存在" "[ -f '${LATEST_PROJECT}通用校验规则.md' ]"
else
    echo "  无项目，跳过检查"
fi
echo ""

# R3: 当前系统上下文
echo "【R3】当前系统上下文"
if [ -n "$LATEST_PROJECT" ]; then
    LATEST_SYSTEM=$(ls -td ${LATEST_PROJECT}*/ 2>/dev/null | head -1)
    if [ -n "$LATEST_SYSTEM" ]; then
        SYSTEM_DIR=$(basename "$LATEST_SYSTEM")
        check_item "最近系统目录: $SYSTEM_DIR" "true"

        # 检查系统产物
        if [ -f "${LATEST_SYSTEM}prd/系统要求规范.md" ]; then
            check_item "系统要求规范.md 存在" "true"
        fi

        if [ -f "${LATEST_SYSTEM}prd/系统交互规范.md" ]; then
            check_item "系统交互规范.md 存在" "true"
        fi

        if [ -d "${LATEST_SYSTEM}prd/modules" ] && [ -n "$(ls -A "${LATEST_SYSTEM}prd/modules" 2>/dev/null)" ]; then
            MODULE_COUNT=$(ls -d "${LATEST_SYSTEM}prd/modules"/*/ 2>/dev/null | wc -l | tr -d ' ')
            check_item "模块级 01/02 文件存在（$MODULE_COUNT 个模块）" "true"
        fi

        if [ -f "${LATEST_SYSTEM}prd/prd-系统结果摘要.md" ]; then
            check_item "系统结果摘要存在" "true"

            # 提取当前阶段
            STAGE=$(grep "当前阶段" "${LATEST_SYSTEM}prd/prd-系统结果摘要.md" 2>/dev/null | head -1 | sed 's/.*: //')
            if [ -n "$STAGE" ]; then
                echo "   📌 当前阶段: $STAGE"
            fi
        fi
    else
        warn_item "项目 $PROJECT_NAME 下暂无系统"
    fi
else
    echo "  无工程项目，跳过检查"
fi
echo ""

# R4: 会话快照
echo "【R4】会话状态快照"
if [ -d ".session_state" ] && [ -n "$(ls -A .session_state 2>/dev/null)" ]; then
    LATEST_SNAPSHOT=$(ls -t .session_state/snapshot_*.json 2>/dev/null | head -1)
    if [ -n "$LATEST_SNAPSHOT" ]; then
        check_item "最近快照: $(basename $LATEST_SNAPSHOT)" "true"
        echo "   💾 快照时间: $(jq -r .timestamp $LATEST_SNAPSHOT 2>/dev/null || echo '无法解析')"
    else
        warn_item "会话状态目录存在但无快照文件"
    fi
else
    warn_item "尚未创建会话状态快照（建议在关键门禁点执行 scripts/session-state.sh save）"
fi
echo ""

# 汇总
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "✅ 通过: ${COLOR_GREEN}${PASSED}${COLOR_RESET}  ❌ 失败: ${COLOR_RED}${FAILED}${COLOR_RESET}  ⚠️  警告: ${COLOR_YELLOW}${WARNINGS}${COLOR_RESET}"

if [ $FAILED -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${COLOR_GREEN}🎉 上下文完整，可以继续工作${COLOR_RESET}"
    exit 0
elif [ $FAILED -eq 0 ]; then
    echo -e "${COLOR_YELLOW}⚠️  上下文基本完整，但有警告项${COLOR_RESET}"
    exit 0
else
    echo -e "${COLOR_RED}❌ 上下文缺失关键信息，建议执行恢复流程${COLOR_RESET}"
    echo ""
    echo "💡 恢复提示："
    echo "   1. 如果是新会话，先扫描 document/ 下项目列表"
    echo "   2. 读取目标项目的 项目级产品摘要.md + 通用异常处理.md + 通用校验规则.md"
    echo "   3. 如果继续技术设计，还需读取系统的 tech/系统级技术标准.md 与 系统级技术规范.md"
    echo "   4. 确定要操作的系统目录后，读取对应的结果摘要和操作记录"
    exit 1
fi
