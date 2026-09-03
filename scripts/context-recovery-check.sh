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

# R1: 工程名是否明确
echo "【R1】工程名与任务目录"
if [ -d "document" ]; then
    PROJECTS=$(ls -d document/*/ 2>/dev/null | wc -l)
    if [ "$PROJECTS" -gt 0 ]; then
        check_item "document/ 目录存在且包含工程" "[ $PROJECTS -gt 0 ]"
        echo "   发现 $PROJECTS 个工程项目"
    else
        check_item "document/ 目录存在且包含工程" "false"
    fi
else
    check_item "document/ 目录存在" "false"
fi
echo ""

# R2: 工程级双文件是否存在
echo "【R2】工程级双文件检查"
LATEST_PROJECT=$(ls -d document/*/ 2>/dev/null | head -1)
if [ -n "$LATEST_PROJECT" ]; then
    PROJECT_NAME=$(basename "$LATEST_PROJECT")
    check_item "产品工程摘要.md 存在" "[ -f '${LATEST_PROJECT}产品工程摘要.md' ]"
    check_item "产品通用规则.md 存在" "[ -f '${LATEST_PROJECT}产品通用规则.md' ]"

    if [ -f "${LATEST_PROJECT}技术通用规则.md" ]; then
        check_item "技术通用规则.md 存在" "true"
    else
        warn_item "技术通用规则.md 不存在（仅技术侧需要）"
    fi
else
    echo "  无工程项目，跳过检查"
fi
echo ""

# R3: 当前任务上下文
echo "【R3】当前任务上下文"
if [ -n "$LATEST_PROJECT" ]; then
    LATEST_TASK=$(ls -d ${LATEST_PROJECT}*_[0-9]*/ 2>/dev/null | sort | tail -1)
    if [ -n "$LATEST_TASK" ]; then
        TASK_DIR=$(basename "$LATEST_TASK")
        check_item "最近任务目录: $TASK_DIR" "true"

        # 检查任务产物
        if [ -f "${LATEST_TASK}prd/01-需求规格说明书.md" ]; then
            check_item "需求规格说明书存在" "true"
        fi

        if [ -f "${LATEST_TASK}prd/02-UI交互规格说明书.md" ]; then
            check_item "UI交互规格说明书存在" "true"
        fi

        if [ -f "${LATEST_TASK}prd/prd-任务结果摘要.md" ]; then
            check_item "任务结果摘要存在" "true"

            # 提取当前阶段
            STAGE=$(grep "当前阶段" "${LATEST_TASK}prd/prd-任务结果摘要.md" 2>/dev/null | head -1 | sed 's/.*: //')
            if [ -n "$STAGE" ]; then
                echo "   📌 当前阶段: $STAGE"
            fi
        fi
    else
        warn_item "工程 $PROJECT_NAME 下暂无任务"
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
    echo "   1. 如果是新会话，先扫描 document/ 下工程列表"
    echo "   2. 读取目标工程的 产品工程摘要.md + 产品通用规则.md"
    echo "   3. 如果继续技术设计，还需读取 技术通用规则.md"
    echo "   4. 确定要操作的任务目录后，读取对应的结果摘要和操作记录"
    exit 1
fi
