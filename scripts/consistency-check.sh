#!/usr/bin/env bash
# =============================================================================
# 项目一致性校验脚本（CI 级静态检查）
# 目的：消解「多文件手动同步漂移」与「无自动校验」两项风险。
# 运行：bash scripts/consistency-check.sh
# 退出码：0=全部通过，1=存在不一致（可被 pre-commit 钩子用作阻塞条件）
# =============================================================================
# 检查项（8）：
#   [1] opencode.json 合法
#   [2] skill 软链接完整性
#   [3] §术语对照表 引用可解析
#   [4] 章节号不变量 + 白名单（含 4a 矛盾映射 / 4b 越界引用）
#   [5] 禁用旧术语扫描
#   [6] 布局语义无绝对几何（02 / 系统交互规范 / 项目级通用规则）
#   [7] self-check「章节号基准」↔ 模板实际骨架一致（防基准自污染）
#   [8] 相对路径深度一致性（项目级文件引用 / tech 侧 prd 引用）
#
# 扫描面（活动骨架文件）：
#   CLAUDE.md / AGENTS.md / CLAUDE.architect.md / AGENTS.architect.md / opencode.json
#   templates/ / skills/ / docs/快速启动指南.md / docs/最佳实践.md
#   scripts/README.md / README.md / SETUP.md
#   （排除 document/ 历史产物、archive/ 过程文档、.opencode/node_modules）
#
# ⚠️ 豁免清单（有意豁免，非漏扫）：
#   1) 历史日志区（README.md / SETUP.md 中 <!-- historical-log:begin/end --> 包裹的区间）
#      —— 理由：日志是「当时状态」的原样记录，其术语 / 章节号 / 产物名已废止，
#         且按约定**只归档不改写**；该区间不构成对当前执行的约束，故不参与扫描。
#         新增日志写在该区间**之外**（日志倒序，新条目在上），仍受全量扫描。
#   2) templates/界面设计要素.md —— 理由：它是**视觉值唯一权威源**，合法承载 px / 色值；
#         检查 6 的几何禁令是「页面规格不得写死几何」，与该文件的定位不冲突。
#   3) archive/ 下的一切过程文档（审计报告 / 优化记录）—— 理由：历史结论快照，不参与执行。
#   4) 历史系统操作记录 / 历史结果摘要（document/ 下）—— 理由：只追加的流水，已 gitignore。
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
# 扫描面构建（历史日志区间自动去豁免）
#   豁免区间内的行不参与检查；镜像行以 [L<原行号>] 前缀保留真实行号
# -----------------------------------------------------------------------------
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
SCAN=()
for f in CLAUDE.md AGENTS.md CLAUDE.architect.md AGENTS.architect.md opencode.json \
         docs/快速启动指南.md docs/最佳实践.md scripts/README.md; do
  [ -e "$f" ] && SCAN+=("$f")
done
SCAN+=(templates/ skills/)
for f in README.md SETUP.md; do
  [ -e "$f" ] || continue
  if grep -q 'historical-log:begin' "$f" 2>/dev/null; then
    awk '/<!--[[:space:]]*historical-log:begin/ {s=1; next}
         /<!--[[:space:]]*historical-log:end/   {s=0; next}
         !s { printf "[L%d] %s\n", FNR, $0 }' "$f" > "$WORK/$f"
    SCAN+=("$WORK/$f")
  else
    SCAN+=("$f")
  fi
done
strip_w() { sed "s|$WORK/||g"; }

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
done < <(grep -rn "术语对照表" "${SCAN[@]}" 2>/dev/null | strip_w)
if [ "$bad_ref" -eq 0 ]; then
  check "所有 §术语对照表 硬引用均指向含该标题的文件" 0
else
  check "所有 §术语对照表 硬引用均指向含该标题的文件" 1 "→ 存在错误引用"
fi

# -----------------------------------------------------------------------------
# 检查 4：章节号不变量 + 白名单校验
#   4a. 异常=§9、未决项=§10 的明确矛盾映射
#   4b. 引用章节号 ∈ 目标文档实际章节号（01/02≤10、03≤5、04≤6、05≤10、系统要求规范≤6、
#       系统级技术标准≤6、系统级技术规范≤16、数据表设计约定≤3、接口契约≤6、代码工程结构说明≤1、00=已废弃）
# -----------------------------------------------------------------------------
echo "[4] 章节号不变量 + 白名单校验"
violation=0

# 4a. 矛盾映射（异常=§9 / 未决项=§10）
while IFS= read -r m; do
  violation=1; echo "    - 矛盾章节引用: $m"
# 4a 的 §9/§10 语义假设源自 01/02 的编号（01/02：§9 异常、§10 未决项）；05 的编号不同（§9 未决项、§10 版本记录），
# 故排除 self-check「章节号基准」登记行（形如 ">   - 05 xxx：§0 ... / §9 未决项 / §10 版本记录。"）——该类行是编号登记而非交叉引用。
# 登记行本身仍受 4b 白名单校验覆盖。
done < <(grep -rnE "§9[^。，、（）()/\n]*未决|§10[^。，、（）()/\n]*异常|未决项[^。，、（）()/\n]*§9|异常[^。，、（）()/\n]*§10" \
  "${SCAN[@]}" 2>/dev/null | strip_w \
  | grep -vE "已知旧术语|项目审计|项目质量|项目评估|:>   - ")

# 4b. 章节号白名单校验
while IFS= read -r ref; do
  [ -z "$ref" ] && continue
  doc=$(echo "$ref" | grep -oE '^(01|02|03|04|05|00|系统要求规范|系统级技术标准|系统级技术规范|数据表设计约定|接口契约|代码工程结构说明)')
  sec=$(echo "$ref" | grep -oE '[0-9]+$')
  [ -z "$doc" ] || [ -z "$sec" ] && continue
  max=99
  case "$doc" in
    01|02) max=10 ;;
    03) max=5 ;;
    04) max=6 ;;
    05) max=10 ;;
    00) max=0 ;;
    系统要求规范) max=7 ;;
    系统级技术标准) max=6 ;;
    系统级技术规范) max=16 ;;
    数据表设计约定) max=3 ;;
    接口契约) max=6 ;;
    代码工程结构说明) max=1 ;;
  esac
  if [ "$sec" -gt "$max" ]; then
    violation=1; echo "    - 越界章节引用: ${ref}（上限 §${max}）"
  fi
done < <(grep -rhoE '(01|02|03|04|05|00|系统要求规范|系统级技术标准|系统级技术规范|数据表设计约定|接口契约|代码工程结构说明)[[:space:]]*§[0-9]+' \
  "${SCAN[@]}" 2>/dev/null | strip_w \
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
  "${SCAN[@]}" 2>/dev/null | strip_w \
  | grep -vE "已知旧术语|项目审计|项目质量|项目评估")
if [ -z "$hits" ]; then
  check "活动文件中无废弃旧术语（接口规划/逐条标注/05-06/产品通用规则/产品工程摘要/技术工程摘要/00-系统概览等已删模板名）" 0
else
  files=$(echo "$hits" | cut -d: -f1 | sort -u | tr '\n' ' ')
  check "活动文件中无废弃旧术语" 1 "→ 命中文件: $files"
fi

# -----------------------------------------------------------------------------
# 检查 6：布局语义无绝对几何（02 / 系统交互规范 / 项目级通用规则 只写语义，不写画布 / 坐标 / px）
#   范围：模板层 02、系统级交互规范、项目级通用异常处理与通用校验规则。实例产物（document/）为旧结构产物，不纳入。
#   注：templates/界面设计要素.md 是视觉值唯一权威源，合法含 px，不扫描（见头部豁免清单 2）。
# -----------------------------------------------------------------------------
echo "[6] 布局语义无绝对几何"
geo_hits=$(grep -nE '画布尺寸|坐标提示|[0-9]+px|x=[0-9]|y=[0-9]|距顶部[0-9]|距左侧[0-9]|[0-9]+×[0-9]+' \
  templates/prototype-agent/module-level/02-模块-UI交互规格.md \
  templates/prototype-agent/system-level/系统交互规范.md \
  templates/prototype-agent/project-level/通用异常处理.md \
  templates/prototype-agent/project-level/通用校验规则.md 2>/dev/null \
  | grep -vE '不写|不得|不重复|禁止用')
if [ -z "$geo_hits" ]; then
  check "02 / 系统交互规范 / 项目级通用规则 无画布·坐标·px 绝对几何（只写语义档位）" 0
else
  files=$(echo "$geo_hits" | cut -d: -f1 | sort -u | tr '\n' ' ')
  check "布局语义无绝对几何" 1 "→ 命中文件: $files"
fi

# -----------------------------------------------------------------------------
# 检查 7：self-check「章节号基准」↔ 模板实际骨架一致
#   基准取自 skills/self-check/SKILL.md 的「章节号基准（模块级 10 章模板，唯一权威）」登记行；
#   权威源 = templates/**（骨架唯一权威源）。比对「§N 标题」与模板 `## N. 标题`。
#   目的：防止基准自身写旧标题（历史缺陷：04 §4 曾写作「并发与锁策略」）反向污染权威源。
#
#   ⚠️ 多字节陷阱（BSD/one-true-awk，本机默认 awk 即此实现）：
#      substr(s,1,1) 与 /^§[0-9]/ 在 UTF-8 下按「字节」工作 —— `§` 占 2 字节、`：` 占 3 字节，
#      直接用「第 1 个字符是否等于 §」或把定界符按 1 字节跳过，会静默失配，
#      表现为「比对 0 个章节」的假通过。故本检查一律用 index() 定位 + length() 显式推进字节。
# -----------------------------------------------------------------------------
echo "[7] self-check 章节号基准 ↔ 模板实际骨架"
declare -A DOC2TPL=(
  ["01 需求规格"]="templates/prototype-agent/module-level/01-模块-需求规格.md"
  ["02 UI 交互"]="templates/prototype-agent/module-level/02-模块-UI交互规格.md"
  ["系统要求规范"]="templates/prototype-agent/system-level/系统要求规范.md"
  ["03 技术规格"]="templates/architect-agent/module-level/03-模块-技术规格.md"
  ["04 数据模型"]="templates/architect-agent/module-level/04-模块-数据模型.md"
  ["05 前端技术规格"]="templates/architect-agent/module-level/05-模块-前端技术规格.md"
  ["接口契约"]="templates/architect-agent/system-level/接口契约.md"
  ["代码工程结构说明"]="templates/architect-agent/system-level/代码工程结构说明.md"
  ["系统级技术标准"]="templates/architect-agent/system-level/系统级技术标准.md"
  ["数据表设计约定"]="templates/architect-agent/system-level/数据表设计约定.md"
  ["系统级技术规范"]="templates/architect-agent/system-level/系统级技术规范.md"
)
# 抽出「文档名 \t §N \t 标题」
awk '
  BEGIN { CL = length("："); SL = length("§") }
  /^>   - / {
    line = $0; sub(/^>   - /, "", line)
    i = index(line, "："); if (i == 0) next
    doc = substr(line, 1, i - 1); body = substr(line, i + CL)
    gsub(/[*`]/, "", doc)
    p = index(doc, "（"); q = index(doc, "("); c = 0
    if (p > 0) c = p; if (q > 0 && (c == 0 || q < c)) c = q
    if (c > 0) doc = substr(doc, 1, c - 1)
    gsub(/^[ \t]+|[ \t]+$/, "", doc)
    if (doc == "") next
    # 按 § 切分（而非按 " / "）：登记行存在「（业务）/ §2」这类无前导空格的写法，
    # 用 " / " 切分会把 §2 并入 §1 而静默漏检；§ 才是真正的章节边界。
    b2 = body
    while (index(b2, "§") > 0) {
      b2 = substr(b2, index(b2, "§"))
      q2 = index(substr(b2, 1 + SL), "§")
      if (q2 > 0) { seg = substr(b2, 1, SL + q2 - 1); b2 = substr(b2, SL + q2) }
      else        { seg = b2; b2 = "" }
      gsub(/[*`]/, "", seg)
      gsub(/^[ \t]+|[ \t]+$/, "", seg)
      rest = substr(seg, 1 + SL)
      if (rest !~ /^[0-9]/) continue
      num = rest; sub(/[^0-9].*$/, "", num)
      # 「§3.1」「§6.3」这类子引用不是章节登记项，跳过
      if (substr(rest, length(num) + 1, 1) != " ") continue
      ttl = substr(rest, length(num) + 1)
      d = index(ttl, "·"); if (d > 0) ttl = substr(ttl, 1, d - 1)
      p = index(ttl, "（"); q = index(ttl, "("); c = 0
      if (p > 0) c = p; if (q > 0 && (c == 0 || q < c)) c = q
      if (c > 0) ttl = substr(ttl, 1, c - 1)
      gsub(/[ \t*`。；;、\/]/, "", ttl)
      if (num != "" && ttl != "") print doc "\t" num "\t" ttl
    }
  }' skills/self-check/SKILL.md > "$WORK/baseline.tsv"

base_bad=0; base_cnt=0; base_seen=0
while IFS=$'\t' read -r doc sec ttl; do
  base_seen=$((base_seen+1))
  tpl="${DOC2TPL[$doc]:-}"
  if [ -z "$tpl" ]; then
    base_bad=1; echo "    - 基准登记了未纳入映射的文档名「${doc}」（请补 DOC2TPL 或修正登记行）"; continue
  fi
  if [ ! -f "$tpl" ]; then base_bad=1; echo "    - 基准登记了不存在的模板: $doc"; continue; fi
  # 模板标题 `## N. 标题`：前缀 "## " + N + ". " = 5 + len(N) 字节，故标题自第 6+len(N) 字节起
  raw="$(awk -v n="$sec" 'index($0, "## " n ". ") == 1 { print substr($0, 6 + length(n)); exit }' "$tpl")"
  if [ -z "$raw" ]; then
    base_bad=1; echo "    - 模板缺章节: $tpl 无「## $sec. 」"; continue
  fi
  tpl_norm="$(awk -v s="$raw" 'BEGIN{ gsub(/[ \t*`。；;、\/]/,"",s); print s }')"
  base_cnt=$((base_cnt+1))
  if [ -z "$tpl_norm" ]; then
    base_bad=1; echo "    - 模板章节标题为空: $doc §$sec"; continue
  fi
  # 双向包含即视为一致（允许基准用简称、模板带括号补充；如 基准「NFR」/ 模板「非功能需求（NFR）」）
  if [[ "$tpl_norm" == *"$ttl"* || "$ttl" == *"$tpl_norm"* ]]; then
    :
  else
    base_bad=1; echo "    - 基准与模板不符: $doc §$sec → 基准「${ttl}」/ 模板「${tpl_norm}」（${tpl}）"
  fi
done < "$WORK/baseline.tsv"

# 7b. 反向完备性：模板中每个「## N. 」章节都必须在基准中登记
#     （防「模板新增章节、基准漏登」这一方向相反的漂移；7 只保证已登记者正确）
declare -A BASE_KEYS=()
while IFS=$'\t' read -r bdoc bsec _bti; do
  [ -z "$bdoc" ] && continue
  BASE_KEYS["$bdoc|$bsec"]=1
done < "$WORK/baseline.tsv"
missing_reg=0
for doc in "${!DOC2TPL[@]}"; do
  tpl="${DOC2TPL[$doc]}"
  [ -f "$tpl" ] || continue
  while IFS= read -r sec; do
    [ -z "$sec" ] && continue
    key="$doc|$sec"
    if [ -z "${BASE_KEYS[$key]:-}" ]; then
      missing_reg=1; base_bad=1
      echo "    - 基准漏登章节: $doc §${sec}（模板 $tpl 存在「## $sec. 」）"
    fi
  done < <(awk 'index($0, "## ") == 1 { s = substr($0, 4); if (s !~ /^[0-9]+\. /) next; n = s; sub(/\..*$/, "", n); print n }' "$tpl")
done
[ "$missing_reg" -eq 0 ] && base_cnt_note="（含反向完备性校验）" || base_cnt_note=""

if [ "$base_seen" -eq 0 ]; then
  check "self-check 章节号基准与模板实际骨架一致" 1 "→ 未从基准登记行抽出任何章节（抽取逻辑失效，勿视为通过）"
elif [ "$base_bad" -eq 0 ]; then
  check "self-check 章节号基准与模板实际骨架一致（比对 $base_cnt 个章节${base_cnt_note}）" 0
else
  check "self-check 章节号基准 ↔ 模板实际骨架" 1 "→ 见上方不符项"
fi

# -----------------------------------------------------------------------------
# 检查 8：相对路径深度一致性
#   规则（唯一权威：skills/self-check 检查 3 的路径深度表）：
#     · 项目级文件（通用异常处理 / 通用校验规则 / 项目级产品摘要 / 项目级技术摘要）
#       模块级模板 → 4 级；系统级模板 → 2 级；系统根（交接索引.md）→ 1 级
#     · tech 侧显式 prd/ 引用：模块级模板 → 3 级；系统级模板 → 1 级
#   范围：templates/**（排除 project-level/ ——其正文含「模块文档应当怎么写」的示例路径，非自身引用）
#   ⚠️ 抽取用 awk（字节安全）而非 ASCII 字符类：文件名含中文时 `[A-Za-z0-9_/.-]*` 会匹配为空。
#      仅校验上述两类「跨层引用」；代码围栏内的示例（期望层级随宿主而变）不在校验范围。
# -----------------------------------------------------------------------------
echo "[8] 相对路径深度一致性（项目级文件 / tech 侧 prd 引用）"
extract_refs() { # 从一行文本抽出全部 ../…*.md 引用（逐个输出，遇空白/反引号截断）
  awk '
    {
      rest = $0
      while ((i = index(rest, "../")) > 0) {
        seg = substr(rest, i)
        if (match(seg, /\.md/) == 0) break
        ref = substr(seg, 1, RSTART + 2)
        for (j = 1; j <= length(ref); j++) {
          ch = substr(ref, j, 1)
          if (ch == " " || ch == "\t" || ch == "`") { ref = substr(ref, 1, j - 1); break }
        }
        print ref
        rest = substr(seg, RSTART + 3)
      }
    }'
}
depth_bad=0; depth_cnt=0
while IFS= read -r hit; do
  f="${hit%%:*}"; rest="${hit#*:}"; line="${rest#*:}"
  base="$(basename "$f")"
  if [[ "$f" == */module-level/* ]]; then exp_proj=4; exp_prd=3
  elif [[ "$f" == */system-level/* ]]; then exp_proj=2; exp_prd=1
  elif [ "$base" = "交接索引.md" ]; then exp_proj=1; exp_prd=1
  else continue; fi
  while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    ref="${ref%%.md*}.md"
    depth="$(awk -v r="$ref" 'BEGIN{ print gsub(/\.\.\//, "", r) }')"
    exp=-1
    case "$ref" in
      *通用异常处理.md|*通用校验规则.md|*项目级产品摘要.md|*项目级技术摘要.md) exp="$exp_proj" ;;
      *prd/*) exp="$exp_prd" ;;
      *) continue ;;
    esac
    depth_cnt=$((depth_cnt+1))
    if [ "$depth" -ne "$exp" ]; then
      depth_bad=1; echo "    - 深度错误: $f:$line 引用 ${ref}（$depth 级，期望 $exp 级）"
    fi
  done < <(extract_refs <<<"$line")
done < <(grep -rn '\.\./' templates/ 2>/dev/null | grep -vE '/project-level/')
if [ "$depth_cnt" -eq 0 ]; then
  check "模板内相对路径深度与文档层级一致" 1 "→ 未抽到任何跨层引用（抽取逻辑失效，勿视为通过）"
elif [ "$depth_bad" -eq 0 ]; then
  check "模板内相对路径深度与文档层级一致（校验 $depth_cnt 处引用）" 0
else
  check "相对路径深度一致性" 1 "→ 见上方深度错误项"
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
