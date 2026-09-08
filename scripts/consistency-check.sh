#!/usr/bin/env bash
# =============================================================================
# 项目一致性校验脚本（CI 级静态检查）
# 目的：消解「多文件手动同步漂移」与「无自动校验」两项风险。
# 运行：bash scripts/consistency-check.sh
# 退出码：0=全部通过，1=存在不一致（可被 pre-commit 钩子用作阻塞条件）
# 范围：仅检查活动骨架文件（排除 document/ 历史产物与 *审计报告*/*质量评估* 等历史记录）
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PASS=0
FAIL=0
FAIL_MSGS=()

check() { # check <描述> <是否通过 0/1> [详细信息]
  local desc="$1"; local ok="$2"; local detail="${3:-}"
  if [ "$ok" -eq 0 ]; then
    PASS=$((PASS+1)); printf "  ✅ %s\n" "$desc"
  else
    FAIL=$((FAIL+1)); FAIL_MSGS+=("$desc ${detail}")
    printf "  ❌ %s  %s\n" "$desc" "$detail"
  fi
}

echo "=================================================="
echo " 项目一致性校验  $(date '+%Y-%m-%d %H:%M')"
echo " 根目录: $ROOT"
echo "=================================================="

# -----------------------------------------------------------------------------
# 检查 1：opencode.json 合法
# -----------------------------------------------------------------------------
echo "[1] opencode.json 语法校验"
if command -v node &>/dev/null; then
  if node -e "JSON.parse(require('fs').readFileSync('opencode.json','utf8'))" 2>/dev/null; then
    check "opencode.json 为合法 JSON" 0
  else
    check "opencode.json 为合法 JSON" 1 "→ 解析失败，请检查格式"
  fi
else
  check "opencode.json 为合法 JSON" 1 "→ 系统未找到 node 命令，请安装 Node.js"
fi

# -----------------------------------------------------------------------------
# 检查 2：skill 软链接完整性（skills/ 与 .opencode/skills/ 一一对应、无悬空）
# -----------------------------------------------------------------------------
echo "[2] skill 软链接完整性"
missing=0; dangling=0; extra=0
shopt -s nullglob 2>/dev/null   # 目录为空/不存在时 glob 不返回字面量，避免误报
for d in skills/*/; do
  name="$(basename "$d")"
  if [ ! -e ".opencode/skills/$name" ]; then missing=1; echo "    - 缺链接: $name"; fi
done
for l in .opencode/skills/*/; do
  [ -e "$l" ] || { dangling=1; echo "    - 悬空链接: $l"; }
done
for l in .opencode/skills/*/; do
  name="$(basename "$l")"
  if [ ! -d "skills/$name" ]; then extra=1; echo "    - 多余链接(无源目录): $name"; fi
done
shopt -u nullglob 2>/dev/null
if [ "$missing$dangling$extra" = "000" ]; then
  check "skills/ 与 .opencode/skills/ 一一对应且无悬空" 0
else
  check "skills/ 与 .opencode/skills/ 一一对应且无悬空" 1 "→ missing=$missing dangling=$dangling extra=$extra"
fi

# -----------------------------------------------------------------------------
# 检查 3：§术语对照表 引用全部可解析（仅校验「某.md 紧跟 术语对照表」的硬引用）
# -----------------------------------------------------------------------------
echo "[3] §术语对照表 引用可解析性"
bad_ref=0
while IFS= read -r line; do
  while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    if [ ! -f "$ref" ]; then bad_ref=1; echo "    - 引用文件不存在: $ref"; continue; fi
    if ! grep -q "术语对照表" "$ref"; then bad_ref=1; echo "    - $ref 不含『术语对照表』标题: 被引用"; fi
  done < <(echo "$line" | grep -oE '[A-Za-z0-9_./-]+\.md[ `」]*§?术语对照表' | sed -E 's/[ `」]*§?术语对照表.*$//')
done < <(grep -rn "术语对照表" CLAUDE.md AGENTS.md CLAUDE.architect.md AGENTS.architect.md opencode.json templates/ skills/ 2>/dev/null)
if [ "$bad_ref" -eq 0 ]; then
  check "所有 §术语对照表 硬引用均指向含该标题的文件" 0
else
  check "所有 §术语对照表 硬引用均指向含该标题的文件" 1 "→ 存在错误引用"
fi

# -----------------------------------------------------------------------------
# 检查 4：章节号不变量 + 白名单校验
#   4a. 异常=§9、未决项=§10 的明确矛盾映射
#   4b. 引用章节号 ∈ 目标文档实际章节号（01/02≤10、03≤5、04≤6、系统要求规范≤6、
#       系统级技术标准≤10、系统级技术规范≤15、数据表设计约定≤7、00=已废弃）
# -----------------------------------------------------------------------------
echo "[4] 章节号不变量 + 白名单校验"
violation=0

# 4a. 矛盾映射（异常=§9 / 未决项=§10）
while IFS= read -r m; do
  violation=1; echo "    - 矛盾章节引用: $m"
done < <(grep -rnE "§9[^。，、（）()/\n]*未决|§10[^。，、（）()/\n]*异常|未决项[^。，、（）()/\n]*§9|异常[^。，、（）()/\n]*§10" \
  CLAUDE.md AGENTS.md CLAUDE.architect.md AGENTS.architect.md opencode.json templates/ skills/ agent/ docs/快速启动指南.md docs/最佳实践.md 2>/dev/null \
  | grep -vE "已知旧术语|项目审计|项目质量|项目评估")

# 4b. 章节号白名单校验
while IFS= read -r ref; do
  [ -z "$ref" ] && continue
  doc=$(echo "$ref" | grep -oE '^(01|02|03|04|00|系统要求规范|系统级技术标准|系统级技术规范|数据表设计约定)')
  sec=$(echo "$ref" | grep -oE '[0-9]+$')
  [ -z "$doc" ] || [ -z "$sec" ] && continue
  max=99
  case "$doc" in
    01|02) max=10 ;;
    03) max=5 ;;
    04) max=6 ;;
    00) max=0 ;;
    系统要求规范) max=6 ;;
    系统级技术标准) max=10 ;;
    系统级技术规范) max=15 ;;
    数据表设计约定) max=7 ;;
  esac
  if [ "$sec" -gt "$max" ]; then
    violation=1; echo "    - 越界章节引用: $ref（上限 §$max）"
  fi
done < <(grep -rhoE '(01|02|03|04|00|系统要求规范|系统级技术标准|系统级技术规范|数据表设计约定)[[:space:]]*§[0-9]+' \
  CLAUDE.md AGENTS.md CLAUDE.architect.md AGENTS.architect.md opencode.json templates/ skills/ agent/ docs/快速启动指南.md docs/最佳实践.md 2>/dev/null \
  | grep -vE "已知旧术语|项目审计|项目质量|项目评估")

if [ "$violation" -eq 0 ]; then
  check "全仓无矛盾映射且章节号引用均未越界" 0
else
  check "章节号不变量 + 白名单校验" 1
fi

# -----------------------------------------------------------------------------
# 检查 5：禁用旧术语扫描（活动文件中不得出现已废弃术语；排除 self-check 的已知术语清单行）
# -----------------------------------------------------------------------------
echo "[5] 禁用旧术语扫描"
hits=$(grep -rnE "接口规划|逐条标注|05-接口设计|06-模块详细设计|产品通用规则|产品工程摘要|技术工程摘要|00[ -]系统概览" \
  CLAUDE.md AGENTS.md CLAUDE.architect.md AGENTS.architect.md opencode.json templates/ skills/ agent/ docs/快速启动指南.md docs/最佳实践.md 2>/dev/null \
  | grep -vE "已知旧术语|项目审计|项目质量|项目评估")
if [ -z "$hits" ]; then
  check "活动文件中无废弃旧术语（接口规划/逐条标注/05-06/产品通用规则/产品工程摘要/技术工程摘要/00-系统概览等已删模板名）" 0
else
  files=$(echo "$hits" | cut -d: -f1 | sort -u | tr '\n' ' ')
  check "活动文件中无废弃旧术语" 1 "→ 命中文件: $files"
fi

# -----------------------------------------------------------------------------
# 汇总
# -----------------------------------------------------------------------------
echo "=================================================="
echo " 结果: 通过 $PASS 项 / 失败 $FAIL 项"
echo "=================================================="
if [ "$FAIL" -gt 0 ]; then
  echo "不一致明细:"
  for m in "${FAIL_MSGS[@]}"; do echo "  - $m"; done
  exit 1
fi
echo "✅ 全部通过，无多文件漂移。"
exit 0
