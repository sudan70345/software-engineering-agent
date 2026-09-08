#!/bin/bash
# 文档一致性自动化校验脚本
# 用途：检查需求包（系统级 系统要求规范 + 系统交互规范 + 模块级 01/02）的完整性和一致性
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
SYSTEM_DIR=""
STRICT_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --system-dir)
            SYSTEM_DIR="$2"
            shift 2
            ;;
        --strict)
            STRICT_MODE=true
            shift
            ;;
        --help)
            echo "用法: $0 [--system-dir <系统目录>] [--strict]"
            echo ""
            echo "选项:"
            echo "  --system-dir <路径>  指定要检查的系统目录（默认：自动扫描最新系统）"
            echo "  --strict             严格模式（警告也视为失败）"
            echo "  --help               显示此帮助信息"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            echo "使用 --help 查看帮助"
            exit 1
            ;;
    esac
done

# 如果未指定系统目录，自动扫描最新系统（document/{项目名}/{系统名}/ 下含 prd/）
if [ -z "$SYSTEM_DIR" ]; then
    SYSTEM_DIR=$(ls -td document/*/*/prd 2>/dev/null | head -1 | sed 's|/prd$||')
fi

if [ -z "$SYSTEM_DIR" ] || [ ! -d "$SYSTEM_DIR" ]; then
    echo -e "${COLOR_RED}❌ 未找到有效的系统目录${COLOR_RESET}"
    echo "请使用 --system-dir 指定系统目录"
    exit 1
fi

echo -e "${COLOR_BLUE}🔍 检查系统: $SYSTEM_DIR${COLOR_RESET}"
echo ""

# 目录路径
PRD_DIR="${SYSTEM_DIR}/prd"
MODULES_DIR="${PRD_DIR}/modules"
PRD_SPEC="${PRD_DIR}/系统要求规范.md"
PRD_INTERACTION="${PRD_DIR}/系统交互规范.md"
PRD_SUMMARY="${PRD_DIR}/prd-系统结果摘要.md"
PRD_LOG="${PRD_DIR}/prd-系统操作记录.md"

# ============================================
# 检查 1: 必要文件存在性
# ============================================
echo "【检查 1】必要文件存在性"

if [ -f "$PRD_SPEC" ]; then
    check_item "系统要求规范.md 存在" "pass"
else
    check_item "系统要求规范.md 存在" "fail"
    echo "   文件不存在，跳过后续检查"
    exit 1
fi

if [ -f "$PRD_INTERACTION" ]; then
    check_item "系统交互规范.md 存在" "pass"
else
    check_item "系统交互规范.md 存在" "warn"
fi

if [ -d "$MODULES_DIR" ] && [ -n "$(ls -A "$MODULES_DIR" 2>/dev/null)" ]; then
    MODULE_COUNT=$(ls -d "$MODULES_DIR"/*/ 2>/dev/null | wc -l | tr -d ' ')
    check_item "modules/ 目录存在（$MODULE_COUNT 个模块）" "pass"
else
    MODULE_COUNT=0
    check_item "modules/ 目录存在且非空" "fail"
    echo "   无模块级 01/02 文件，跳过后续检查"
    exit 1
fi

if [ -f "$PRD_SUMMARY" ]; then
    check_item "prd-系统结果摘要.md 存在" "pass"
else
    check_item "prd-系统结果摘要.md 存在" "warn"
fi

if [ -f "$PRD_LOG" ]; then
    check_item "prd-系统操作记录.md 存在" "pass"
else
    check_item "prd-系统操作记录.md 存在" "warn"
fi

echo ""

# ============================================
# 检查 2: 每个模块 01/02 文件成对存在
# ============================================
echo "【检查 2】模块 01/02 文件成对存在"

MISSING_PAIR=0
for mod_dir in "$MODULES_DIR"/*/; do
    mod_name=$(basename "$mod_dir")
    if [ ! -f "${mod_dir}01-${mod_name}-需求规格.md" ]; then
        echo "   缺少: ${mod_dir}01-${mod_name}-需求规格.md"
        MISSING_PAIR=1
    fi
    if [ ! -f "${mod_dir}02-${mod_name}-UI交互规格.md" ]; then
        echo "   缺少: ${mod_dir}02-${mod_name}-UI交互规格.md"
        MISSING_PAIR=1
    fi
done

if [ "$MISSING_PAIR" -eq 0 ]; then
    check_item "全部模块 01/02 文件成对存在" "pass"
else
    check_item "模块 01/02 文件成对存在" "fail"
fi

echo ""

# ============================================
# 检查 3: FR-x 编号连续性（模块内连续）
# ============================================
echo "【检查 3】FR-x 编号连续性（模块内）"

FR_TOTAL=0
FR_DISCONT=0
for req_file in "$MODULES_DIR"/*/01-*-需求规格.md; do
    [ -f "$req_file" ] || continue
    mod_name=$(basename "$(dirname "$req_file")")
    FR_LIST=$(grep -oE 'FR-[0-9]+' "$req_file" | sort -u | sed 's/FR-//' | sort -n)
    FR_COUNT=$(echo "$FR_LIST" | wc -w | tr -d ' ')
    [ "$FR_COUNT" -eq 0 ] && continue
    FR_TOTAL=$((FR_TOTAL + FR_COUNT))

    EXPECTED=1
    for num in $FR_LIST; do
        if [ "$num" -ne "$EXPECTED" ]; then
            FR_DISCONT=1
            echo "   模块 ${mod_name} FR-x 跳号: $FR_LIST"
            break
        fi
        EXPECTED=$((EXPECTED + 1))
    done
done

if [ "$FR_TOTAL" -eq 0 ]; then
    check_item "FR-x 编号连续性" "warn"
    echo "   未找到任何 FR-x 编号"
elif [ "$FR_DISCONT" -eq 0 ]; then
    check_item "FR-x 编号连续（共 $FR_TOTAL 条）" "pass"
else
    check_item "FR-x 编号连续性" "fail"
fi

echo ""

# ============================================
# 检查 4: 场景[Sx] 编号连续性（系统要求规范 §2）
# ============================================
echo "【检查 4】场景[Sx] 编号连续性"

SCENE_LIST=$(grep -oE '场景\[S[0-9]+\]' "$PRD_SPEC" | sed 's/场景\[S//' | sed 's/\]//' | sort -u | sort -n)
SCENE_COUNT=$(echo "$SCENE_LIST" | wc -w | tr -d ' ')

if [ "$SCENE_COUNT" -eq 0 ]; then
    check_item "场景[Sx] 编号连续性" "warn"
    echo "   未找到任何场景[Sx] 编号"
else
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
# 检查 5: 输入/输出/校验/异常章节完整性（01 §5/§6/§7/§9）
# ============================================
echo "【检查 5】01 章节完整性（§5 输入/§6 输出/§7 校验/§9 异常）"

SECTION_MISSING=0
for req_file in "$MODULES_DIR"/*/01-*-需求规格.md; do
    [ -f "$req_file" ] || continue
    mod_name=$(basename "$(dirname "$req_file")")

    HAS_S5=$(grep -cE '^## 5\. 输入' "$req_file" || true)
    HAS_S6=$(grep -cE '^## 6\. 输出' "$req_file" || true)
    HAS_S7=$(grep -cE '^## 7\. 校验' "$req_file" || true)
    HAS_S9=$(grep -cE '^## 9\. 异常' "$req_file" || true)

    if [ "$HAS_S5" -eq 0 ] || [ "$HAS_S6" -eq 0 ] || [ "$HAS_S7" -eq 0 ] || [ "$HAS_S9" -eq 0 ]; then
        echo "   模块 ${mod_name} 缺少章节: §5输入/$HAS_S5 §6输出/$HAS_S6 §7校验/$HAS_S7 §9异常/$HAS_S9"
        SECTION_MISSING=1
    fi
done

if [ "$SECTION_MISSING" -eq 0 ]; then
    check_item "全部 01 文件具备 §5/§6/§7/§9 章节" "pass"
else
    check_item "01 章节完整性" "fail"
fi

echo ""

# ============================================
# 检查 6: 版本号一致性（同模块 01/02 版本一致）
# ============================================
echo "【检查 6】版本号一致性（同模块 01/02）"

VERSION_MISMATCH=0
for mod_dir in "$MODULES_DIR"/*/; do
    mod_name=$(basename "$mod_dir")
    req_file="${mod_dir}01-${mod_name}-需求规格.md"
    ui_file="${mod_dir}02-${mod_name}-UI交互规格.md"
    [ -f "$req_file" ] && [ -f "$ui_file" ] || continue

    VERSION_01=$(grep -E '^\*\*文档版本\*\*: v[0-9]+\.[0-9]+' "$req_file" | head -1 | grep -oE 'v[0-9]+\.[0-9]+')
    VERSION_02=$(grep -E '^\*\*文档版本\*\*: v[0-9]+\.[0-9]+' "$ui_file" | head -1 | grep -oE 'v[0-9]+\.[0-9]+')

    if [ -z "$VERSION_01" ] || [ -z "$VERSION_02" ]; then
        continue
    elif [ "$VERSION_01" != "$VERSION_02" ]; then
        echo "   模块 ${mod_name} 版本不一致: 01=$VERSION_01, 02=$VERSION_02"
        VERSION_MISMATCH=1
    fi
done

if [ "$VERSION_MISMATCH" -eq 0 ]; then
    check_item "同模块 01/02 版本号一致" "pass"
else
    check_item "版本号一致性" "fail"
fi

echo ""

# ============================================
# 检查 7: 禁止项检查（职责边界）
# ============================================
echo "【检查 7】职责边界（禁止技术实现）"

FORBIDDEN_API=0
FORBIDDEN_DB=0
FORBIDDEN_STACK=0
for req_file in "$MODULES_DIR"/*/01-*-需求规格.md; do
    [ -f "$req_file" ] || continue

    n1=$(grep -ciE '(^|[^a-z])(GET|POST|PUT|DELETE|PATCH)[[:space:]]*/[a-z]|/api/[a-z]|RESTful' "$req_file" || echo "0")
    n2=$(grep -ciE 'CREATE TABLE|ALTER TABLE|DROP TABLE|表名:|字段类型:' "$req_file" || echo "0")
    n3=$(grep -ciE '(Redis|Kafka|MySQL|MongoDB|PostgreSQL|Elasticsearch)' "$req_file" || echo "0")

    FORBIDDEN_API=$((FORBIDDEN_API + n1))
    FORBIDDEN_DB=$((FORBIDDEN_DB + n2))
    FORBIDDEN_STACK=$((FORBIDDEN_STACK + n3))
done

if [ "$FORBIDDEN_API" -gt 0 ]; then
    check_item "无接口定义" "fail"
    echo "   发现 $FORBIDDEN_API 处疑似接口定义（/api/、RESTful、HTTP method）"
else
    check_item "无接口定义" "pass"
fi

if [ "$FORBIDDEN_DB" -gt 0 ]; then
    check_item "无数据模型" "fail"
    echo "   发现 $FORBIDDEN_DB 处疑似数据模型定义（CREATE TABLE、表名、字段类型）"
else
    check_item "无数据模型" "pass"
fi

if [ "$FORBIDDEN_STACK" -gt 0 ]; then
    check_item "无技术选型" "warn"
    echo "   发现 $FORBIDDEN_STACK 处疑似技术选型（Redis/Kafka/MySQL 等中间件）"
    echo "   提示：如为业务术语可忽略；如为技术实现需移至 tech/ 03"
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
    echo "   1. 模块 01/02 文件缺失：检查 系统要求规范.md §5 模块清单与 modules/ 目录是否对齐"
    echo "   2. FR-x 编号不连续：检查各模块 01 §2 功能要点，确保 FR-1、FR-2、... 连续"
    echo "   3. 章节缺失：检查 01 §5 输入/§6 输出/§7 校验/§9 异常"
    echo "   4. 版本号不一致：检查同模块 01 和 02 的文档版本是否相同"
    echo "   5. 职责边界违反：01-*-需求规格.md 不应包含接口定义、数据模型、技术选型"
    exit 1
fi
