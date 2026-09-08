# 双智能体功能审计报告（第二轮 · 从头全量）

**审计日期**：2026-09-07
**审计对象**：prototype-agent（需求分析智能体）、architect-agent（技术分析智能体）
**审计维度**：链路完整性 / 合理性 / 简洁性 / 准确性；md 定义 ↔ skill 关联；模板准确性；双智能体关联完整性
**审计范围**：`CLAUDE.md`、`CLAUDE.architect.md`、`AGENTS.md`、`AGENTS.architect.md`、`agent/*.md`、`skills/*/SKILL.md`（10 个）、`templates/**`（24 个）、`opencode.json`、`claude.json`、`scripts/*`、`document/` 实际产物（只读，不修改）。

---

## 一、结论速览

**主线（主指令 + 模块级模板 + 实际产物）已收敛到「模块化架构」，方向正确；但「外围文件」大量滞留旧版，形成三处权威源互相矛盾的深水区。当前状态：新任务可直接跑通核心链路（00→01/02→03/04），但 ① 通用规则落点三处说法冲突、② 三个「首建复制模板」仍是旧版、③ 第三套旧指令与 pencil-executor 未迁移、④ 校验脚本整体旧口径，会系统性误导执行。**

核心判断一句话：**「脊柱已正，四肢未齐」**——四层统一模型（FR-x 脊柱键）、模块归纳、分层精简、门禁闭环这些主干设计经得起推敲，但从「单文件大文档」迁到「模块化分层」时，只有主指令和模块级模板跟上了，通用规则 skill、记录类模板、原型 skill、agent 子指令、脚本五处没同步。

---

## 二、prototype-agent 链路审计

### 2.1 链路完整性（✅ 主干完整，🟡 通用规则落点分裂）

四阶段链路清晰：会话启动硬约束 → Step0-2 归属研判 → 阶段1 系统架构（门禁1）→ 阶段2 逐模块（门禁2）→ 决策门禁 →（可选）原型生成。双重门禁 + 决策门禁 + 版本联动 + 上下文恢复 R1-R4 完整，异常反问 5 句式 + Fallback 策略到位。**主干无缺口**。

但**通用规则落点存在三处权威源互相矛盾**（详见 P0-1），是当前 prototype 侧最严重的结构分裂。

### 2.2 合理性（✅）

- 功能优先、UI 承载、弹窗二分（复杂弹窗→辅助页面[N-A]/简单弹窗内联）判据清晰。
- 「一次采集、双向落档」避免重复访谈，合理。
- 跨系统影响三分类（复用/扩展/变更）+ 变更类授权硬门禁，边界严谨。

### 2.3 简洁性（✅ 主指令，🟡 skill 有冗余）

- CLAUDE.md 通过「唯一权威源 + 其他文件仅引用」克制了重复定义（职责边界、版本规则、术语表均标注「唯一权威」）。
- 但 `business-architecture`/`page-specs`/`delivery` 三个 skill 各自重述了一遍「通用规则三文件」，且与主指令口径冲突（见 P0-1），属冗余且有害。
- `page-specs` 输入清单「00-系统概览.md」重复两行；`delivery` 输入清单「00-系统概览.md」重复两行、Step2 通用规则读取重复列了一遍。

### 2.4 准确性（🔴 问题集中）

- `page-specs` 的沟通步骤 1a–1m **缺「关键交互行为」**（02 §5），从 §4 功能组件直接跳 §6 页面状态，会导致 02 文档缺关键交互内容（见 P1）。
- `page-specs` 通用规则引用路径 `../../通用异常处理.md` 无论哪种落点方案都不对（见 P1）。
- 三个 skill 内部自洽但与主指令/模板矛盾（P0-1）。

### 2.5 md ↔ skill ↔ 模板关联

| 关联点 | 状态 |
|--------|------|
| CLAUDE.md → business-architecture（阶段1） | 🟡 skill 的通用规则落点与主指令冲突 |
| CLAUDE.md → page-specs（阶段2） | 🟡 通用规则落点冲突 + 缺 §5 交互步骤 + 引用路径错 |
| CLAUDE.md → delivery（结果摘要） | 🟡 skill 描述的新摘要结构 ≠ 旧版模板 |
| CLAUDE.md → pencil-executor（原型） | 🔴 整个 skill 未迁移（旧术语/旧路径） |

---

## 三、architect-agent 链路审计

### 3.1 链路完整性（✅ 主干完整）

阶段 0（系统级技术标准）+ 阶段 1（需求解析）+ 阶段 2（技术规格）+ 阶段 3（数据模型）+ 阶段 4（收口），4 道门禁（0/1/2/3）+ self-check 前置自检，闭环完整。「需求翻译器 / 不做架构设计」定位精准，模块归纳 5 判据、宁细勿粗、待人工校准边界清晰。**主干无缺口**。

### 3.2 合理性（✅）

- 分层精简（系统级标准/规范/数据表约定 → 模块级 03/04 只补差异）去重合理。
- 机器可读（schema/状态码/错误码）+ 伪代码可译双诉求并存，贴合「编程智能体可直接消费」。
- self-check 三道自检（FR-x 追溯 / 场景覆盖 / 章节号·引用·术语一致性）设计优秀，是全局最严谨的一份文件。

### 3.3 简洁性（🟡 有重复步骤）

- `tech-architecture` skill Step 4 与 Step 6 内容重复（都是「模块完成后回填系统级规范 + 生成依赖清单」）。
- `AGENTS.architect.md` 阶段2「第一步：生成系统级标准与规范」与阶段0 职责重叠（阶段0 已确认系统级标准）。

### 3.4 准确性（🔴 问题集中）

- `spec-analysis` Step 4 记录写错文件名「tech-任务操作记录.md」+ 不存在的模板路径（见 P1）。
- `tech-architecture` Step 3 + `agent/architect-agent.md` 仍用旧「9 子项」表述，与 03 模板「接口内联」结构不符（见 P1）。
- `AGENTS.architect.md` 归属判定扫描锚点与主指令不一致（见 P1）。

### 3.5 md ↔ skill ↔ 模板关联

| 关联点 | 状态 |
|--------|------|
| CLAUDE.architect.md → tech-common-rules（阶段0） | ✅ 一致 |
| CLAUDE.architect.md → spec-analysis（阶段1） | 🟡 记录文件名/模板路径错 |
| CLAUDE.architect.md → tech-architecture（阶段2） | 🟡 9 子项旧表述残留 |
| CLAUDE.architect.md → data-model（阶段3） | ✅ 一致 |
| CLAUDE.architect.md → self-check | ✅ 一致（章节基准最全） |
| CLAUDE.architect.md → tech-delivery（收口） | 🟡 交接索引模板旧版（见 P0-3） |

---

## 四、双智能体关联完整性审计

### 4.1 FR-x 四层追溯（✅ 设计完整）

FR-x 为唯一脊柱键贯穿四层（01 场景→用户故事 / 02 页面→功能组件 / 03 模块→功能点 / 研发代码模块），self-check 提供全链路追溯矩阵。设计完整。

### 4.2 数据独立与共享锚点（✅ 设计正确，🟡 实际产物未对齐）

- 设计上：同系统目录共享锚点，prd/ 归 prototype、tech/ 归 architect，`交接索引.md` 汇总。正确。
- 实际上：`document/` 三个项目的锚点文件名**与指令定义不符**（见 P0-4），且残留旧结构（`tech/common/`、`00-系统技术架构总览.md`、单文件 03/04）。

### 4.3 命名一致性（🔴 严重漂移）

项目摘要文件名在**指令、模板、实际产物三层各叫一套**（详见 P0-4 表），会话启动硬约束「扫描含 `项目级产品摘要.md` 的目录」会在现有项目上**全部落空**。

### 4.4 配置注册（🟡 平台分叉）

- `opencode.json`：已重写为模块化流程，两个 agent prompt 正确，并正确声明「CLAUDE.md 仅引用其术语对照表」。✅
- `claude.json`：仅注册 pencil MCP，**未注册两个智能体的指令文件**（CLAUDE.md/CLAUDE.architect.md/AGENTS.md/AGENTS.architect.md），与 opencode.json 注册语义不一致。🟡

### 4.5 校验脚本匹配度（🔴 整体旧口径）

`validate-docs.sh` 整体针对旧单文件 14 章架构；`consistency-check.sh` 的「检查4 章节号不变量」仍用「异常=§13/未决项=§14」旧口径；`session-state.sh`/`context-recovery-check.sh`/`scripts/README.md` 残留旧术语。详见 P1/P2。

---

## 五、分级问题清单

### P0（阻断级：导致执行失败 / 首建产物结构错误 / 权威源冲突）

| # | 问题 | 位置 | 影响 |
|---|------|------|------|
| P0-1 | **通用规则落点三处矛盾**：主指令（CLAUDE.md 目录图 + AGENTS.md 门禁话术 + opencode.json + 01/02 模板 + 实际产物）采用 `prd/common/` 三文件（通用异常处理/通用校验规则/通用交互规范）；但 `business-architecture`/`page-specs`/`delivery` 三个 skill 采用「项目级 通用异常处理+通用校验规则 + 系统级 `系统交互规范.md`」，且模板位置分裂（通用异常/校验在 project-level、系统交互规范在 system-level、模板标题叫「通用交互规范」） | CLAUDE.md L212-215、AGENTS.md L120-122、opencode.json、01/02 模板 §9.1；business-architecture Step2、page-specs 输出结构、delivery 输入 | 执行时通用规则文件落点不确定，模块文档引用路径错乱 |
| P0-2 | **prd-系统结果摘要.md 模板 + prd-系统操作记录.md 模板是旧版**：结果摘要模板仍是「任务结果摘要」+ 旧 14 章单文件（`01-需求规格说明书.md`、`01 §14 未决项`、`§10-§13` 输入输出校验异常）；操作记录模板「系统目录 `{系统名}_{YYYYMMDD}`」带日期后缀 + 「工程名」 | templates/prototype-agent/system-level/prd-系统结果摘要.md、prd-系统操作记录.md | delivery「首建复制模板」会产出错误结构的摘要/操作记录 |
| P0-3 | **交接索引.md 模板是旧版**：标题「交接索引—{任务名称}」、旧「工程/任务目录」、旧单文件「prd/01-需求规格说明书.md」「tech/03-技术规格说明书.md」；tech-delivery 明确「以本模板为权威源」 | templates/交接索引.md | 交接给编程智能体的清单指向不存在的旧文件 |
| P0-4 | **项目摘要文件名三层各叫一套**：指令=「项目级产品摘要/项目级技术摘要」；模板=「项目级产品摘要/项目级技术摘要」；实际产物=「产品工程摘要/产品项目摘要/技术工程摘要/技术项目摘要」 | document/物资集采…、document/超跃、document/食堂订货服务平台 | 会话启动硬约束「扫描含 项目级产品摘要.md 的目录」在现有项目上全部落空 |

### P1（严重漂移：导致执行偏差 / 步骤缺失 / 文件写错）

| # | 问题 | 位置 |
|---|------|------|
| P1-1 | `pencil-executor` skill 整体未迁移：旧「工程/任务/task_dir/task_name」术语、`.pen` 与截图位置（`document/{工程名}/{task_dir}/`）与 CLAUDE.md 目录图（`prd/{system_name}.pen`、`prd/screenshots/`）不一致、「prd-任务结果摘要.md/prd-任务操作记录.md」旧名 | skills/pencil-executor/SKILL.md（全文） |
| P1-2 | 第三套旧指令未清理：`agent/prototype-agent.md`（frontmatter「document/{工程名}/{任务名}_{YYYYMMDD}」+ 旧「工程/任务」）；`agent/architect-agent.md`（description「03-技术规格说明书/04-数据模型说明书」旧单文件 + 正文「9 子项」+「01 §2.4」） | agent/prototype-agent.md、agent/architect-agent.md |
| P1-3 | 「9 子项」与「接口内联」两套表述并存：tech-architecture Step3 + agent/architect-agent.md 仍写「功能点 9 子项（功能描述/输入/…/接口契约/伪代码/关联数据）」，03 模板已改为「§2 接口清单内联输入/校验/伪代码/输出 schema/异常/关联数据」 | skills/tech-architecture/SKILL.md Step3、agent/architect-agent.md |
| P1-4 | `spec-analysis` Step4 记录写错：`tech/tech-任务操作记录.md` + `templates/tech-任务操作记录.md`（不存在），应为 `tech-系统操作记录.md` + `templates/architect-agent/system-level/tech-系统操作记录.md` | skills/spec-analysis/SKILL.md L78 |
| P1-5 | `page-specs` 缺「关键交互行为」沟通步骤：02 模板有 §5 关键交互，self-check 章节基准有 §5，但 skill 1g→1m 映射从 §4 直接跳 §6 | skills/page-specs/SKILL.md 1g–1m |
| P1-6 | `page-specs` 通用规则引用路径错：`../../通用异常处理.md`（从 modules/{模块}/ 向上两级只到 prd/，common/ 方案应为 `../../common/通用异常处理.md`，项目级方案应为 `../../../`） | skills/page-specs/SKILL.md L384-386 |
| P1-7 | `AGENTS.architect.md` 归属判定扫描锚点与主指令不一致：本文件「含 `产品通用规则.md` 的项目目录」，CLAUDE.architect.md「含 `项目级技术摘要.md` 的项目目录」 | AGENTS.architect.md L32 vs CLAUDE.architect.md L87 |
| P1-8 | `validate-docs.sh` 整体旧版：旧单文件「01-需求规格说明书.md」+ 旧 14 章「§10 输入/§11 输出/§12 校验/§13 异常」+ 旧「prd-任务结果摘要.md」；pre-commit hook 会误判 | scripts/validate-docs.sh |
| P1-9 | `consistency-check.sh` 检查4「章节号不变量」用旧口径「异常=§13/未决项=§14」，当前模块级 10 章是「异常=§9/未决项=§10」；脚本自身即漂移源 | scripts/consistency-check.sh L88-102 |

### P2（一致性瑕疵）

| # | 问题 | 位置 |
|---|------|------|
| P2-1 | CLAUDE.md 术语表标题「三层统一模型」但内含「四层统一模型」 | CLAUDE.md L103、L117 |
| P2-2 | CLAUDE.md 目录图 tech/ 子目录写旧单文件「03-技术规格说明书.md/04-数据模型说明书.md」 | CLAUDE.md L234-235 |
| P2-3 | CLAUDE.md 异常反问句式②引用「系统级技术标准」（技术侧概念），产品侧应为「产品通用规则」 | CLAUDE.md L189 |
| P2-4 | 模板「系统要求规范.md」名 ≠ 产物「00-系统概览.md」名 | templates/prototype-agent/system-level/系统要求规范.md |
| P2-5 | 模板「系统交互规范.md」文件名 ≠ 内容标题「通用交互规范」 | templates/prototype-agent/system-level/系统交互规范.md |
| P2-6 | 02 模板 §8.1 引用「00-系统概览.md §2.1」（不存在；00 无 UI 风格章节）；UI 风格落点三处说法不一（AGENTS.md→common/通用交互规范；02 模板→00 §2.1/界面设计要素） | templates/…/02-模块-UI交互规格.md L154 |
| P2-7 | tech-系统结果摘要.md 模板引用「../系统结果摘要.md」，应为「../prd/prd-系统结果摘要.md」 | templates/…/tech-系统结果摘要.md L5、L43 |
| P2-8 | 界面设计要素.md 引用旧文件名「02-UI交互规格说明书.md」 | templates/界面设计要素.md L7、L217、L232 |
| P2-9 | 系统级技术标准 §10 命名不统一：模板「本规则文件变更记录」/ self-check「变更记录」/ tech-common-rules「维护记录」 | 三处 |
| P2-10 | tech-delivery skill 标题「技术任务结果摘要 Skill」旧术语「任务」 | skills/tech-delivery/SKILL.md L13 |
| P2-11 | business-architecture description 与正文不一致：description「生成 系统交互规范.md」、正文「common/ 三文件」 | skills/business-architecture/SKILL.md L3 vs 正文 |
| P2-12 | scripts/session-state.sh、context-recovery-check.sh、README.md 残留旧术语「工程/任务/01-需求规格说明书.md」 | scripts/* |
| P2-13 | AGENTS.architect.md 阶段2「第一步生成系统级标准与规范」与阶段0 职责重叠 | AGENTS.architect.md L106-118 |
| P2-14 | claude.json 未注册两个智能体指令文件（仅 mcpServers.pencil） | claude.json |
| P2-15 | document/ 实际产物残留旧结构（`tech/common/`、`00-系统技术架构总览.md`、单文件 03/04、`运动社区_20260708` 日期后缀）——历史产物，保持现状，仅记录 | document/** |

---

## 六、修复建议（按优先级，先方案后执行）

> 均为流程类改动，落盘前先给逐文件方案、经确认后再改。`document/` 全程不动。

### 第一步（P0，阻断项，最高优先）

1. **定夺通用规则落点**（P0-1）：以「common/ 三文件」为唯一口径（主指令 + 01/02 模板 + 实际产物已三处一致），反向修正三个 skill（business-architecture / page-specs / delivery）为「common/ 通用异常处理 + 通用校验规则 + 通用交互规范」；同步修正模板位置（通用异常处理/通用校验规则 从 project-level 移到 system-level，与系统交互规范同目录；或统一在 project-level——二选一，需用户定）。
2. **重写三个旧版记录/交接模板**（P0-2、P0-3）：prd-系统结果摘要.md、prd-系统操作记录.md、交接索引.md 三个模板对齐「项目/系统/模块 + 无日期后缀 + 模块级 01/02/03/04」新结构。
3. **定夺项目摘要命名**（P0-4）：指令/模板已统一为「项目级产品摘要/项目级技术摘要」，需同步决定是否重命名 document/ 下既有旧名文件（`产品工程摘要`/`产品项目摘要`/`技术工程摘要`/`技术项目摘要`）——涉及 document/，须用户明确授权；或仅在指令中补充「兼容扫描旧名」的过渡规则。

### 第二步（P1，执行偏差）

4. 重写/迁移 `pencil-executor` skill（P1-1）与 `agent/*.md`（P1-2）到新术语与新路径。
5. 清理「9 子项」表述 → 「接口内联 6 要素」（P1-3）；修 spec-analysis 记录文件名（P1-4）；补 page-specs §5 交互步骤（P1-5）；修 page-specs 引用路径（P1-6）；统一 AGENTS.architect.md 扫描锚点（P1-7）。
6. 重写 `validate-docs.sh` 对齐模块级 10 章；修 `consistency-check.sh` 检查4 章节号口径（P1-8、P1-9）。

### 第三步（P2，收尾）

7. 批量修 P2 清单（术语表标题、目录图 tech/ 结构、反问句式、模板命名、引用路径、界面设计要素旧文件名、§10 命名、tech-delivery 标题、scripts 术语、claude.json 注册）。

---

## 七、证据索引

- 主指令：`CLAUDE.md`（prototype）、`CLAUDE.architect.md`（architect）
- 沟通话术：`AGENTS.md`、`AGENTS.architect.md`
- 子指令（旧）：`agent/prototype-agent.md`、`agent/architect-agent.md`
- skill（10）：business-architecture / page-specs / delivery / pencil-executor（prototype 侧）；tech-common-rules / spec-analysis / tech-architecture / data-model / self-check / tech-delivery（architect 侧）
- 模板（24）：templates/prototype-agent/{module-level,system-level,project-level}、templates/architect-agent/{module-level,system-level,project-level}、templates/交接索引.md、templates/界面设计要素.md
- 配置：opencode.json、claude.json、.claude/settings.local.json
- 脚本：scripts/{consistency-check,validate-docs,session-state,context-recovery-check}.sh、scripts/README.md
- 实际产物（只读）：document/物资集采 SAAS 平台、document/超跃、document/食堂订货服务平台
