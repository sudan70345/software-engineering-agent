#!/bin/bash
# 文档一致性自动化校验脚本
# 用途：检查需求包（01-需求规格说明书.md + 02-UI交互规格说明书.md）的完整性和一致性
# 使用场景：pre-commit hook、CI pipeline、手动校验

set -e

COLOR_GREEN="\033[0;32m"
COLOR_RED="\033[0;31m"
COLOR_YELLOW="\033[1;33m"
COLOR_BLUE="\033[0;34m"
COLOR_RESET="\033[0m"

PASSED=0
FAILED=0
WARNINGS=0

check_item() {
    local label="$1"
    local result="$2"

    if [ "$result" = "pass" ]; then
        echo -e "${COLOR_GREEN}✅${COLOR_RESET} $label"
        ((PASSED++))
        return 0
    elif [ "$result" = "warn" ]; then
        echo -e "${COLOR_YELLOW}⚠️${COLOR_RESET} $label"
        ((WARNINGS++))
        return 0
    else
        echo -e "${COLOR_RED}❌${COLOR_RESET} $label"
        ((FAILED++))
        return 1
    fi
}

# 解析参数
TASK_DIR=""
STRICT_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --task-dir)
            TASK_DIR="$2"
            shift 2
            ;;
        --strict)
            STRICT_MODE=true
            shift
            ;;
        --help)
            echo "用法: $0 [--task-dir <任务目录>] [--strict]"
            echo ""
            echo "选项:"
            echo "  --task-dir <路径>  指定要检查的任务目录（默认：自动扫描最新任务）"
            echo "  --strict           严格模式（警告也视为失败）"
            echo "  --help             显示此帮助信息"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            echo "使用 --help 查看帮助"
            exit 1
            ;;
    esac
done

# 如果未指定任务目录，自动扫描最新任务
if [ -z "$TASK_DIR" ]; then
    LATEST_PROJECT=$(ls -d document/*/ 2>/dev/null | head -1)
    if [ -n "$LATEST_PROJECT" ]; then
        TASK_DIR=$(ls -d ${LATEST_PROJECT}*_[0-9]*/ 2>/dev/null | sort | tail -1)
    fi
fi

if [ -z "$TASK_DIR" ] || [ ! -d "$TASK_DIR" ]; then
    echo -e "${COLOR_RED}❌ 未找到有效的任务目录${COLOR_RESET}"
    echo "请使用 --task-dir 指定任务目录"
    exit 1
fi

echo -e "${COLOR_BLUE}🔍 检查任务: $TASK_DIR${COLOR_RESET}"
echo ""

# 文件路径
PRD_01="${TASK_DIR}prd/01-需求规格说明书.md"
PRD_02="${TASK_DIR}prd/02-UI交互规格说明书.md"
PRD_SUMMARY="${TASK_DIR}prd/prd-任务结果摘要.md"
PRD_LOG="${TASK_DIR}prd/prd-任务操作记录.md"

# ============================================
# 检查 1: 必要文件存在性
# ============================================
echo "【检查 1】必要文件存在性"

if [ -f "$PRD_01" ]; then
    check_item "01-需求规格说明书.md 存在" "pass"
else
    check_item "01-需求规格说明书.md 存在" "fail"
    echo "   文件不存在，跳过后续检查"
    exit 1
fi

if [ -f "$PRD_02" ]; then
    check_item "02-UI交互规格说明书.md 存在" "pass"
else
    check_item "02-UI交互规格说明书.md 存在" "fail"
    echo "   文件不存在，跳过后续检查"
    exit 1
fi

if [ -f "$PRD_SUMMARY" ]; then
    check_item "prd-任务结果摘要.md 存在" "pass"
else
    check_item "prd-任务结果摘要.md 存在" "warn"
fi

if [ -f "$PRD_LOG" ]; then
    check_item "prd-任务操作记录.md 存在" "pass"
else
    check_item "prd-任务操作记录.md 存在" "warn"
fi

echo ""

# ============================================
# 检查 2: FR-x 编号连续性
# ============================================
echo "【检查 2】FR-x 编号连续性"

FR_LIST=$(grep -oE 'FR-[0-9]+' "$PRD_01" | sort -u | sed 's/FR-//' | sort -n)
FR_COUNT=$(echo "$FR_LIST" | wc -w)

if [ "$FR_COUNT" -eq 0 ]; then
    check_item "FR-x 编号连续性" "warn"
    echo "   未找到任何 FR-x 编号"
else
    # 检查是否连续
    EXPECTED=1
    IS_CONTINUOUS=true
    for num in $FR_LIST; do
        if [ "$num" -ne "$EXPECTED" ]; then
            IS_CONTINUOUS=false
            break
        fi
        EXPECTED=$((EXPECTED + 1))
    done

    if [ "$IS_CONTINUOUS" = true ]; then
        check_item "FR-x 编号连续（FR-1 到 FR-$FR_COUNT）" "pass"
    else
        check_item "FR-x 编号连续性" "fail"
        echo "   发现跳号或乱序: $FR_LIST"
    fi
fi

echo ""

# ============================================
# 检查 3: 场景[Sx] 编号连续性
# ============================================
echo "【检查 3】场景[Sx] 编号连续性"

SCENE_LIST=$(grep -oE '场景\[S[0-9]+\]' "$PRD_01" | sed 's/场景\[S//' | sed 's/\]//' | sort -u | sort -n)
SCENE_COUNT=$(echo "$SCENE_LIST" | wc -w)

if [ "$SCENE_COUNT" -eq 0 ]; then
    check_item "场景[Sx] 编号连续性" "warn"
    echo "   未找到任何场景[Sx] 编号"
else
    # 检查是否连续
    EXPECTED=1
    IS_CONTINUOUS=true
    for num in $SCENE_LIST; do
        if [ "$num" -ne "$EXPECTED" ]; then
            IS_CONTINUOUS=false
            break
        fi
        EXPECTED=$((EXPECTED + 1))
    done

    if [ "$IS_CONTINUOUS" = true ]; then
        check_item "场景[Sx] 编号连续（场景[S1] 到 场景[S$SCENE_COUNT]）" "pass"
    else
        check_item "场景[Sx] 编号连续性" "fail"
        echo "   发现跳号或乱序: $SCENE_LIST"
    fi
fi

echo ""

# ============================================
# 检查 4: 页面[N] 与 02 §4 一致性
# ============================================
echo "【检查 4】页面[N] 与 02 §4 一致性"

# 从 02 §3 页面总览提取页面清单
PAGES_IN_OVERVIEW=$(grep -oE '页面\[[0-9]+(-[A-Z])?\]' "$PRD_02" | grep -E '^\| 页面' | awk '{print $2}' | sort -u)

# 从 02 §4 提取实际存在的页面章节
PAGES_IN_SECTION4=$(grep -oE '^### 页面\[[0-9]+(-[A-Z])?\]' "$PRD_02" | sed 's/### //' | sed 's/:.*//' | sort -u)

PAGES_IN_OVERVIEW_COUNT=$(echo "$PAGES_IN_OVERVIEW" | wc -w)
PAGES_IN_SECTION4_COUNT=$(echo "$PAGES_IN_SECTION4" | wc -w)

if [ "$PAGES_IN_OVERVIEW_COUNT" -eq 0 ] || [ "$PAGES_IN_SECTION4_COUNT" -eq 0 ]; then
    check_item "页面[N] 与 §4 一致性" "warn"
    echo "   页面总览或 §4 内容为空，跳过检查"
else
    # 简单比较数量（严格比较需要更复杂的逻辑）
    if [ "$PAGES_IN_OVERVIEW_COUNT" -eq "$PAGES_IN_SECTION4_COUNT" ]; then
        check_item "页面[N] 数量一致（总览 $PAGES_IN_OVERVIEW_COUNT = §4 $PAGES_IN_SECTION4_COUNT）" "pass"
    else
        check_item "页面[N] 数量一致" "fail"
        echo "   总览: $PAGES_IN_OVERVIEW_COUNT 页，§4: $PAGES_IN_SECTION4_COUNT 页"
    fi
fi

echo ""

# ============================================
# 检查 5: FR-x 的输入/输出/校验/异常完整性
# ============================================
echo "【检查 5】FR-x 的输入/输出/校验/异常完整性"

if [ "$FR_COUNT" -gt 0 ]; then
    # 检查 §10-§13 是否存在
    HAS_SECTION_10=$(grep -c '^## 10\. 输入' "$PRD_01" || echo "0")
    HAS_SECTION_11=$(grep -c '^## 11\. 输出' "$PRD_01" || echo "0")
    HAS_SECTION_12=$(grep -c '^## 12\. 校验' "$PRD_01" || echo "0")
    HAS_SECTION_13=$(grep -c '^## 13\. 异常' "$PRD_01" || echo "0")

    if [ "$HAS_SECTION_10" -gt 0 ] && [ "$HAS_SECTION_11" -gt 0 ] && \
       [ "$HAS_SECTION_12" -gt 0 ] && [ "$HAS_SECTION_13" -gt 0 ]; then
        check_item "§10-§13 章节存在" "pass"
    else
        check_item "§10-§13 章节存在" "fail"
        echo "   缺少必要章节（§10 输入/§11 输出/§12 校验/§13 异常）"
    fi
else
    check_item "FR-x 输入/输出/校验/异常完整性" "warn"
    echo "   无 FR-x，跳过检查"
fi

echo ""

# ============================================
# 检查 6: 版本号一致性
# ============================================
echo "【检查 6】版本号一致性"

VERSION_01=$(grep -E '^- 文档版本: v[0-9]+\.[0-9]+' "$PRD_01" | head -1 | grep -oE 'v[0-9]+\.[0-9]+')
VERSION_02=$(grep -E '^- 文档版本: v[0-9]+\.[0-9]+' "$PRD_02" | head -1 | grep -oE 'v[0-9]+\.[0-9]+')

if [ -z "$VERSION_01" ] || [ -z "$VERSION_02" ]; then
    check_item "版本号一致性" "warn"
    echo "   未找到版本号信息"
elif [ "$VERSION_01" = "$VERSION_02" ]; then
    check_item "版本号一致（01 与 02 均为 $VERSION_01）" "pass"
else
    check_item "版本号一致性" "fail"
    echo "   01: $VERSION_01，02: $VERSION_02"
fi

echo ""

# ============================================
# 检查 7: 禁止项检查（职责边界）
# ============================================
echo "【检查 7】职责边界（禁止技术实现）"

# 检查是否包含接口定义（/api/、RESTful、HTTP method）
FORBIDDEN_PATTERN_1=$(grep -ciE '(^|[^a-z])(GET|POST|PUT|DELETE|PATCH)[[:space:]]*/[a-z]|/api/[a-z]|RESTful' "$PRD_01" || echo "0")

# 检查是否包含数据库表名（CREATE TABLE、ALTER TABLE、表名模式）
FORBIDDEN_PATTERN_2=$(grep -ciE 'CREATE TABLE|ALTER TABLE|DROP TABLE|表名:|字段类型:' "$PRD_01" || echo "0")

# 检查是否包含技术选型（Redis、Kafka、MySQL、MongoDB 等明确中间件）
FORBIDDEN_PATTERN_3=$(grep -ciE '(Redis|Kafka|MySQL|MongoDB|PostgreSQL|Elasticsearch)' "$PRD_01" || echo "0")

if [ "$FORBIDDEN_PATTERN_1" -gt 0 ]; then
    check_item "无接口定义" "fail"
    echo "   发现 $FORBIDDEN_PATTERN_1 处疑似接口定义（/api/、RESTful、HTTP method）"
else
    check_item "无接口定义" "pass"
fi

if [ "$FORBIDDEN_PATTERN_2" -gt 0 ]; then
    check_item "无数据模型" "fail"
    echo "   发现 $FORBIDDEN_PATTERN_2 处疑似数据模型定义（CREATE TABLE、表名、字段类型）"
else
    check_item "无数据模型" "pass"
fi

if [ "$FORBIDDEN_PATTERN_3" -gt 0 ]; then
    check_item "无技术选型" "warn"
    echo "   发现 $FORBIDDEN_PATTERN_3 处疑似技术选型（Redis/Kafka/MySQL 等中间件）"
    echo "   提示：如为业务术语（如「用户在 Redis 商城下单」）可忽略；如为技术实现需移至 03"
else
    check_item "无技术选型" "pass"
fi

echo ""

# ============================================
# 汇总
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "✅ 通过: ${COLOR_GREEN}${PASSED}${COLOR_RESET}  ❌ 失败: ${COLOR_RED}${FAILED}${COLOR_RESET}  ⚠️  警告: ${COLOR_YELLOW}${WARNINGS}${COLOR_RESET}"

if [ $FAILED -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${COLOR_GREEN}🎉 文档完整性和一致性检查通过${COLOR_RESET}"
    exit 0
elif [ $FAILED -eq 0 ]; then
    if [ "$STRICT_MODE" = true ]; then
        echo -e "${COLOR_YELLOW}⚠️  严格模式：存在警告项，视为失败${COLOR_RESET}"
        exit 1
    else
        echo -e "${COLOR_YELLOW}⚠️  文档基本完整，但有警告项${COLOR_RESET}"
        exit 0
    fi
else
    echo -e "${COLOR_RED}❌ 文档存在完整性或一致性问题${COLOR_RESET}"
    echo ""
    echo "💡 修复建议："
    echo "   1. FR-x 编号不连续：检查 01 §7 功能要点，确保 FR-1、FR-2、... 连续"
    echo "   2. 页面[N] 不一致：检查 02 §3 页面总览与 §4 逐页规格是否对齐"
    echo "   3. 输入/输出/校验/异常缺失：检查 01 §10-§13，每个 FR 应有对应条目或标「无」"
    echo "   4. 版本号不一致：检查 01 和 02 的文档版本是否相同"
    echo "   5. 职责边界违反：01-需求规格说明书.md 不应包含接口定义、数据模型、技术选型"
    exit 1
fi
