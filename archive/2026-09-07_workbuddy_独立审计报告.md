# 双智能体工程骨架文件独立审计报告

**审计日期**：2026-09-07
**审计范围**：`software-engineering-agent` 仓库骨架文件——根级指令（CLAUDE.md / CLAUDE.architect.md / AGENTS.md / AGENTS.architect.md / opencode.json / claude.json / README.md / SETUP.md）、`agent/`（2 份）、`skills/`（10 份 SKILL.md）、`templates/`（20 份）、`scripts/`（4 脚本 + README + pre-commit.sample）、`docs/`（2 份活文档 + 3 份历史记录）
**排除项**（按审计要求）：`.workbuddy/`、`document/`（产物目录，仅做 1 次诊断性路径验证）、既有审计/质量评估报告、`docs/优化实施报告.md`、`docs/优化改动清单.md`、`docs/优化实施完成总结.md`（2026-09-02 历史记录）
**审计性质**：只读分析，未修改任何文件。所有改进建议均待确认后另行实施。

---

## 一、总体结论

**骨架主链路（指令 ↔ skills ↔ templates ↔ opencode.json 注册）总体自洽、职责边界清晰，四层引用设计是健康的；但「面向人的活文档」（docs/）与「注册/引导外围」（agent/、SETUP.md、脚本扫描范围）存在系统性滞后，且存在 3 处会实际误导 agent 行为的规范冲突（FR-x 编号、六维确认口径、03/04 相对路径）。**

| 维度 | 评级 | 概要 |
|------|------|------|
| 关联性（引用链） | 🟡 中 | 主链路引用基本可解析；docs/ 两份活文档整体停留在旧架构，agent/architect-agent.md 存在指向不存在章节的错误引用 |
| 准确性（内容正确） | 🟡 中 | 03/04 模板相对路径基准偏移一级；SETUP 配置指引与实际配置不符；六维确认存在 4 个互不一致的版本 |
| 权威与单一（单一权威源） | 🟢 良 | 职责边界/版本规则/术语表/门禁判定均单点定义、他处引用，未发现权威逻辑被复制重定义；主要问题是**自动校验防线（consistency-check.sh）的扫描范围与实际漂移点错位**，已知漂移均落在其盲区 |

问题分级统计：**P0（必须修）3 项、P1（应修）6 项、P2（建议修）11 项**。

---

## 二、审计发现明细

### 【P0 · 必须修】（3 项）

#### P0-1 docs/快速启动指南.md 整体停留在旧架构，且被 README 列为新用户第一入口

**位置**：`docs/快速启动指南.md` 全文；放大源：`README.md` 快速开始章节、`SETUP.md`
**问题**（与 v2.0 现行架构直接冲突点）：

| 指南内容 | 现行架构（权威源） |
|---------|------------------|
| 术语用「工程 / 任务」 | 已统一为「项目 / 系统」（CLAUDE.md §术语对照表） |
| 读取「项目级产品摘要.md + **产品通用规则.md**」 | 产品通用规则.md 已废弃，现为 通用异常处理.md + 通用校验规则.md（CLAUDE.md 会话启动硬约束） |
| 目录 `{工程名}/{任务名}_{YYYYMMDD}/` | 现为 `{项目名}/{系统名}/`（无日期后缀） |
| `01-需求规格说明书.md` / `02-UI交互规格说明书.md` 单文件 | 现为 `modules/{模块名}/01-{模块名}-需求规格.md` + `02-...UI交互规格.md` 按模块拆分 |
| `prd-任务结果摘要.md` / `prd-任务操作记录.md` | 现为 `prd-系统结果摘要.md` / `prd-系统操作记录.md` |
| `tech/03-技术规格说明书.md` 单文件 | 现为 `tech/modules/{模块}/03-{模块}-技术规格.md` + 系统级技术标准/规范/数据表设计约定 |

**影响**：新用户按此指南操作会以旧术语、旧目录、旧文件名与 agent 沟通，直接触发理解偏差；「产品通用规则.md」在 consistency-check.sh 检查 5 中属禁用旧术语，docs/ 不在扫描范围故未被拦截。
**背景说明**：2026-09-07 早前修复轮曾按「历史保留」约定跳过 docs/；但 **README/SETUP 至今仍将两份文档作为活入口**（"阅读快速启动指南"/"遇到问题时查阅最佳实践"），「保留为历史」与「作为活文档引用」两种定位互相矛盾——这正是本项列 P0 的原因。
**建议**：三选一——① 按现行 CLAUDE.md/AGENTS.md 全文重写（推荐）；② 维持保留决定，但 README/SETUP 撤下入口并指向 CLAUDE.md §工作流程总览；③ 保留入口但在文档头部加「内容基于旧架构（工程/任务体系），术语以 CLAUDE.md 为准」警示。

#### P0-2 docs/最佳实践.md 大面积旧术语与旧章节引用，README 引其为求助入口

**位置**：`docs/最佳实践.md` §2.4/§3.1/§3.2/§5.3/§7.2/§8.1
**问题**：
- `产品通用规则.md` 残留 6 处（§3.1、§3.2、§5.2、§8.1）——废弃文件名；
- §2.4/§5.3 引用旧文件名 `01-需求规格说明书.md` / `02-UI交互规格说明书.md` / `03-技术规格说明书.md`；
- §7.2 称「阶段 1 **八项**判据」且示例含「端与功能类型」——AGENTS.md 现行判据为 **7 项**且无「端与功能类型」；
- §3.3 跨任务影响研判示例引用 `01 §7 FR-5`——现行 01 模板 FR-x 位于 **§2**、§7 为校验规范（旧章节号）；
- §3.3/§7.1 全文用「任务」语境（现为系统）。

**影响**：与 P0-1 同源，用户按旧章节号/旧判据数与 agent 对话会造成沟通口径漂移。
**建议**：同 P0-1，重写或归档；至少先修正禁用术语与「八项判据」两处硬错误。

#### P0-3 agent/architect-agent.md 引用不存在的「CLAUDE.architect.md §术语对照表」

**位置**：`agent/architect-agent.md` 第 13 行
**问题**：`详细术语定义……详见 CLAUDE.architect.md §术语对照表（唯一权威源）`——**CLAUDE.architect.md 中不存在「术语对照表」章节**；术语对照表唯一权威源在 `CLAUDE.md §术语对照表`（opencode.json architect prompt 第 7 条、AGENTS.architect.md 均引用正确位置）。
**影响**：architect-agent 按 agent 定义文件寻找术语权威源会落空；「唯一权威源」的指向本身错误，属权威链断裂。
**佐证**：consistency-check.sh 检查 3（§术语对照表引用可解析）扫描范围为 `CLAUDE.md AGENTS.md CLAUDE.architect.md AGENTS.architect.md opencode.json templates/ skills/`——**不含 agent/**，而检查 4/5 含 agent/，恰好放过了这条错误引用。
**建议**：① 将该行改为 `CLAUDE.md §术语对照表`；② consistency-check.sh 检查 3 的文件列表补入 `agent/`（见 C-1）。

---

### 【P1 · 应修】（6 项）

#### P1-1 FR-x 编号规则三处冲突（opencode.json vs 模板/page-specs vs 校验脚本）

**位置与口径**：

| 文件 | 口径 |
|------|------|
| `opencode.json` prototype prompt 第 7 条 | FR-x **跨模块全局连续唯一**，禁止每模块从 FR-1 重编号 |
| `skills/page-specs/SKILL.md` 1b、`templates/.../01-模块-需求规格.md` §2 示例 | FR-1、FR-2…（**模块内从 1 起编**） |
| `scripts/validate-docs.sh` 检查 3 | 校验「FR-x 编号连续性（**模块内**）」，逐模块期望从 FR-1 连续 |

**影响**：注册指令与模板/脚本相抵触——若 agent 遵循 opencode.json 全局编号，validate-docs.sh 将全部模块报「跳号」；反之遵循模板则违反注册指令。self-check 的 FR-x 追溯矩阵（01↔02↔03↔04）依赖编号可全局定位，两口径下语义不同。
**建议**：需用户决策统一方向——**方案 A（推荐，改动最小）**：确认现行实践为「模块内从 FR-1 起编、FR-x 以「模块名+FR-x」组合全局定位」，修订 opencode.json 第 7 条并同步 self-check 追溯矩阵的键定义；**方案 B**：维持全局连续，重写 page-specs 话术、01/02 模板示例、validate-docs.sh 检查 3。两案均需同步 delivery（FR 数量统计）与 tech-侧 TFP 映射表说明。

#### P1-2 「六维确认」存在 4 个互不一致的版本，且 data-model skill 要求超出 04 模板承载

**位置与口径**：

| 文件 | 「六维」定义 |
|------|-------------|
| `skills/data-model/SKILL.md` frontmatter description | 表 / 字段 / **建表语句 / 索引语句** / **表关联** / 并发约束 |
| `skills/data-model/SKILL.md` Step 7 | 表 / 表字段 / 建表语句 / **索引语句** / 并发约束 / **字段状态机** |
| `AGENTS.architect.md` 门禁 3 话术 | 实体与表清单 / 建表 DDL / **索引映射表** / 并发约束 / 数据一致性 / **字段默认规则** |
| `CLAUDE.architect.md` 阶段 3 工作清单 | 实体识别 / 建表 DDL / 索引映射表 / 并发保护与数据一致性 / 字段默认规则（5 项，未称六维） |

**且**：data-model Step 3 要求「每表必须产出**两份**可执行 DDL（建表语句 + 索引语句 CREATE INDEX）」、Step 7 含「字段状态机」维度，但 **04 模板无独立「索引语句 DDL」章节**（索引以 `KEY idx_...` 内联于 CREATE TABLE + §3 查询场景→索引映射表）、**无状态机章节**（§5 为数据一致性约束）。self-check 的 04 章节号基准与 04 模板一致（无此两节）。
**影响**：skill 指令与模板权威源（templates/ 为骨架唯一权威源）漂移；按 skill 执行会在 04 产物中生成模板没有的章节，按模板执行则无法满足 skill 的门禁 3 校验口径。
**建议**：以 04 模板 + self-check 基准为准收敛——在 data-model skill 内统一六维为「表/字段/建表 DDL（含内联索引）/查询场景→索引映射/并发与锁/一致性约束（含状态机字段标注）」，删除「独立索引语句 DDL」「字段状态机独立维度」表述，或将状态机并入 §5 一致性约束；frontmatter description 与 Step 7 对齐；AGENTS.architect/CLAUDE.architect 同步措辞。

#### P1-3 03/04 模板相对路径基准偏移一级，tech 侧引用按文件位置解析全部断链

**位置**：`templates/architect-agent/module-level/03-模块-技术规格.md`（上游引用、§0、§4）、`04-模块-数据模型.md` §0；同样表述扩散至 `skills/tech-architecture`（「引用 ../系统级技术标准.md」）、`skills/data-model`（「../数据表设计约定.md」）、`skills/self-check`（「03 引用 ../../prd/modules/...」）。
**问题**：产物文件实际位于 `tech/modules/{模块名}/`，模板内路径却以 `tech/modules/` 为基准书写：

| 模板写法 | 按文件位置实际解析到 | 应为 |
|---------|-------------------|------|
| `../系统级技术标准.md` | tech/modules/系统级技术标准.md ✗ | `../../系统级技术标准.md` |
| `../数据表设计约定.md`、`../模块间接口依赖清单.md` | tech/modules/ 下 ✗ | `../../…` |
| `../../prd/modules/{模块名}/01-….md` | tech/prd/… ✗ | `../../../prd/modules/…` |

**对照**：prototype 侧模板以产物自身目录为基准且层级正确（`../../../../通用异常处理.md`、`../../系统交互规范.md`），两侧基准不一致。用 document/ 既有产物做诊断验证，生成文件继承了模板的同款错误路径写法。
**影响**：03/04 产物中的相对引用对编程智能体/人不可达；self-check 检查 3 的「跨文档引用正确性」校验口径本身带同款错误。
**建议**：统一约定「模板内相对路径一律以**产物文件自身目录**为基准」，修正 03/04 模板与三个 skill 中的路径（03/04 → 系统级文件 `../../`；→ prd `../../../prd/…`）；将该约定写入 consistency-check 检查项或 self-check 基准。

#### P1-4 「用户故事」在模型/话术/收口侧存在，但 01 模板无承载章节

**位置**：
- `CLAUDE.md` §术语对照表四层模型：01 原子单元 = 「用户故事 / 功能点 FR-x」；§职责边界允许项含「用户故事」；
- `AGENTS.md` 阶段 2 模块话术①含用户故事句式、模块确认模板含「用户故事: [N 条]」；
- `skills/delivery/SKILL.md` Step 1 从 01 提取「用户故事（数量）」。

但 `templates/.../01-模块-需求规格.md` 10 章结构（定位/功能要点/实体/规则/输入/输出/校验/处理流程/异常/未决项）**无用户故事章节**，page-specs 采集步骤也未收集；prd-系统结果摘要模板无用户故事展示位。
**影响**：agent 按 AGENTS.md 话术收集了用户故事却无处落档，或按模板直接跳过——两侧文件对「01 应包含什么」回答不一致。
**建议**：二选一——① 01 模板 §2 功能要点表增加「用户故事」列（或在 §1 模块定位下增设小节），page-specs 同步采集项；② 从 CLAUDE.md 模型表、AGENTS.md 话术/确认模板、delivery 提取项中删除用户故事表述。以模板为权威源收敛。

#### P1-5 SETUP.md 配置指引与实际配置文件不符，Pencil 安装来源存疑

**位置**：`SETUP.md` 配置步骤 vs `opencode.json` / `claude.json`
**问题**：
- SETUP 指引「将 `mcp.pencil.enabled` 从 `false` 改为 `true`」并示例 `"type": "stdio", "command": "pencil-mcp"`——实际 opencode.json 已是 `enabled: true`、`type: "local"`、command 为 `/Applications/Pencil.app/.../mcp-server-darwin-arm64` 全路径数组，指引照做反而会破坏现有配置；
- `claude.json` 用 `pencil-mcp` 命令，opencode.json 用 Pencil.app 内置二进制——同一 MCP 两套不一致的启动方式；
- SETUP 给出的下载地址（pencil.evolus.vn）与 npm 包名（`@pencil/mcp-server`）是否与实际使用的 Pencil.app 桌面端为同一产品**无法从仓库内证实，需人工核实**。
**建议**：SETUP 按实际 opencode.json 重写该节；统一 claude.json 与 opencode.json 的 Pencil MCP 启动方式（或注明各自适用宿主）；核实并更正 Pencil 安装来源表述。

#### P1-6 自动校验防线扫描范围与实际漂移点错位（consistency-check.sh）

**位置**：`scripts/consistency-check.sh` 检查 3 / 检查 4 / 检查 5
**问题**：
- 检查 3（术语对照表引用可解析）文件列表**缺 `agent/`**——P0-3 的错误引用正落在此盲区；
- 检查 5（禁用旧术语）文件列表**缺 `docs/`**——P0-1/P0-2 的「产品通用规则」「工程/任务」「旧文件名」等大量命中均落在此盲区（脚本注释自述排除审计/质量报告，但顺带把活文档 docs/ 也排除了）；
- 检查 4（章节号不变量）仅防 §9↔§10 互换，防不住 CLAUDE.md:196 的「01 §14 / 02 §6」类旧编号残留（建议扩充为「引用章节号 ∈ 目标模板实际章节号」白名单校验，self-check 已有全部基准可复用）。
**影响**：pre-commit hook 已安装、脚本设计合理，但三条最严重的漂移全部绕过了它——校验体系给人「已防线化」的错觉。
**建议**：检查 3 补 `agent/`；检查 5 补 `docs/快速启动指南.md docs/最佳实践.md`（历史报告仍排除）；检查 4 升级为章节号白名单校验（以 self-check 章节号基准为数据源）。

---

### 【P2 · 建议修】（11 项）

| # | 位置 | 问题 | 建议 |
|---|------|------|------|
| P2-1 | `CLAUDE.md` L196（异常沟通指引 Fallback） | 登记「01 §14 / 02 §6 未决项」——旧章节号，现行模板为 01 §10 / 02 §10 | 改为 §10 / §10；纳入章节号白名单校验 |
| P2-2 | `CLAUDE.md` L448、`agent/prototype-agent.md` L55、`skills/pencil-executor/SKILL.md` L134 | CLAUDE.md 声称 Critical 约束「全量定义于 pencil-executor『Critical 级约束』」——该 SKILL **无此命名章节**；SKILL 内部又引用不存在的「Critical 约束 14-19」编号 | 在 pencil-executor 内增设「Critical 级约束」编号章节（或修正 CLAUDE.md 索引措辞为指向「前置依赖 + 各 Step ★ 标记」），删除悬空编号 |
| P2-3 | `skills/pencil-executor/SKILL.md` Step 3 | 「扫描每个主页面的『弹窗』『交互定义』章节」——02 模板无「交互定义」章（实为 §5 关键交互行为、§9 辅助页面） | 改为「§9 辅助页面（弹窗）与 §5 关键交互行为」 |
| P2-4 | `skills/delivery/SKILL.md` Step 3 vs `templates/.../prd-系统结果摘要.md` | delivery 以 §1–§10 编号描述章节且命名有差（「§7 模块状态覆盖清单」vs 模板「页面状态覆盖清单」）；Step 4 条目模板中「系统要求规范」重复列出、标签不一（系统要求规范/系统级规范） | delivery 章节描述与模板实际标题逐一对齐；修正重复条目 |
| P2-5 | `AGENTS.md` 阶段 2 话术① vs 01 模板 §2 | 话术承诺 FR-x 附「所属角色 / 优先级 P0-P2 / 所属场景」，模板表列为「触发条件 / 前置依赖 / 执行顺序」，字段集不一致 | 统一（建议话术对齐模板字段；若需保留优先级/场景则改模板） |
| P2-6 | `SETUP.md` 项目文件清单 | skills/ 只列 8 个（缺 tech-common-rules、self-check）；scripts/ 缺 consistency-check.sh、validate-docs.sh、README.md；docs/ 缺 2 份 | 按实际目录补全清单 |
| P2-7 | `README.md` 修改日志 2026-09-04 条目 | 描述「独立 common/ 目录（通用异常/校验/交互）」——common/ 为已废弃中间形态，与 README 自身目录结构图（无 common/）矛盾 | 改为「项目级 通用异常处理/通用校验规则 + 系统级 系统交互规范」 |
| P2-8 | `scripts/validate-docs.sh`、`context-recovery-check.sh`、`session-state.sh` | 「自动扫描最新系统 / 最近项目」实为路径字典序取首个（find \| head -1 / sort \| tail -1），非按修改时间 | 改用 `ls -t` / `stat` 按 mtime 取最新，或改文档措辞 |
| P2-9 | `skills/self-check/SKILL.md`、`skills/spec-analysis/SKILL.md` | 以「00」「00 §2」代称《系统要求规范》——「00-系统概览」产物名已废弃（模板名=产物名），简称残留且未列入 self-check 自身「已知旧术语」与检查 5 禁用表 | 统一改用「系统要求规范.md §2」；将「00 简称」补入旧术语清单 |
| P2-10 | `skills/tech-delivery/SKILL.md` frontmatter | 「刷新**工程级** 项目级技术摘要.md」——「工程级」为已统一废弃口径（项目/系统）；另 交接索引.md 的创建责任未落在任何 prototype 侧 skill（tech-delivery 假设其已由 prototype 创建，CLAUDE.md 仅提及引用） | 改「项目级」；在 delivery 或 CLAUDE.md 明确交接索引.md 的创建时机（建议：需求包定稿收口时创建 prd 部分骨架） |
| P2-11 | `templates/.../系统级技术规范.md` §3、`templates/.../模块间接口依赖清单.md` §4 | 示例「`/api/v1/order-list` → `/api/v1/order-list`」自映射无信息量；标题「数据表所属权归」语病 | 示例改为 `/api/v1/order_list → /api/v1/order-list`；标题改「数据表归属」 |

另记一处**表述性小疵**（不计级）：`CLAUDE.md` Step R4「prototype-agent → 只写 prd/ 子目录」之后列出的 `项目级产品摘要.md / 通用异常处理.md / 通用校验规则.md` 实际位于 prd/ 之外（项目级），建议改为「只写产品侧文件（prd/ 子目录 + 项目级产品三件）」。

---

## 三、分维度小结

**关联性**：主链路（CLAUDE ↔ skills ↔ templates ↔ opencode.json）引用经逐一核对基本可解析、无悬空文件引用；skills 引用的模板路径 100% 存在；`.opencode/skills/` 软链 10/10 完整无悬空。断点集中在**外围层**：docs/ 两份活文档（整体滞后一个架构代际）、agent/architect-agent.md（指向不存在章节）、03/04 模板相对路径（基准偏移）。

**准确性**：核心业务规则（门禁序列、prd/tech 隔离、版本号规则、模块归纳 5 判据、FR→TFP 映射、四层模型术语）在指令/skill/模板间表述一致。错误集中在：FR-x 编号口径冲突、六维确认 4 版本并存、相对路径层级、SETUP 配置指引过时、脚本「最新」语义不准。

**权威与单一**：这是本工程最强的部分——职责边界（禁止技术实现三类项）、版本规则、术语对照表、门禁判定逻辑均单点定义、其余文件显式声明「不重复定义、仅引用」，未发现权威逻辑被复制重定义的实例；self-check 的「章节号基准」集中定义是亮点设计。主要短板是**防线错位**：consistency-check.sh 的三条检查范围各自漏掉一个已实际发生漂移的目录，使「单一权威源 + 自动校验」的闭环在盲区失效。

---

## 四、值得肯定的方面

1. **prd/ 只写 ↔ tech/ 只写的双向隔离**在指令、skill 自检、模板头部、注册 prompt 四层一致贯彻，无一处越界授权。
2. **「他处仅引用、不重复定义」的权威源纪律**执行良好：AGENTS.md 明确「话术指引不重复逻辑」、agent/*.md 明确「不重复定义」、模板间视觉令牌单源引用（界面设计要素.md）链路完整。
3. **skills 前置自检（🛡️ 执行前自检）全覆盖** 10/10，且统一回指 CLAUDE(.architect).md 恢复检查点。
4. **soft-link 注册机制**（skills/ ↔ .opencode/skills/）+ 对应完整性校验，设计干净且当前零悬空。
5. **pre-commit hook 已实际安装**（.git/hooks/pre-commit 存在且可执行），骨架文件纳入 git 管线的意图已落地。

---

## 五、改进实施建议（待确认后执行，本次未动任何文件）

**第一批（P0，预计涉及 3 个文件 + 1 个脚本）**
1. 修正 `agent/architect-agent.md` L13 → `CLAUDE.md §术语对照表`；
2. `scripts/consistency-check.sh`：检查 3 补 `agent/`、检查 5 补 docs/ 两份活文档；
3. 决策 docs/ 两份活文档处置：重写（推荐，工作量约 1 份文档当量 × 2）或临时归档 + README 撤入口。

**第二批（P1，需逐项方案确认）**
4. FR-x 编号口径二选一（A：模块内起编，改 opencode.json；B：全局连续，改模板+脚本）——**需用户拍板**；
5. 六维确认口径收敛 + data-model skill 对齐 04 模板（删独立索引 DDL/状态机维度，或改模板增设章节——**需用户拍板方向**）；
6. 03/04 模板与 tech 侧三个 skill 的相对路径统一修正（基准=产物文件自身目录）；
7. 用户故事承载二选一（模板补章节 vs 上下游删表述）——**需用户拍板**；
8. SETUP.md 配置节按实际 opencode.json 重写 + Pencil 安装来源人工核实；
9. consistency-check 检查 4 升级为章节号白名单校验（复用 self-check 基准）。

**第三批（P2，机械修正，约 11 处，可一次提交）**
按上表 P2-1 ~ P2-11 逐项落点修正，并跑通 `scripts/consistency-check.sh` 全绿后提交。

---

## 附录：本次核对通过的抽样项

- opencode.json 两个 agent 注册 prompt 与各自指令文件的角色/阶段/门禁描述一致（除 FR-x 条，见 P1-1）；
- 10 个 skills 的「🛡️ 执行前自检」回指的恢复检查点章节（CLAUDE.md / CLAUDE.architect.md §上下文恢复检查点）均存在；
- 20 个模板文件名与 SETUP.md 模板清单（templates 部分）、各 skill 引用的模板路径完全一致；
- prototype 侧相对路径层级（../../../../ 至项目级、../../ 至 prd/ 系统级）全部正确；
- 系统要求规范/系统交互规范/通用异常处理/通用校验规则四份模板间的视觉令牌引用链（→ 界面设计要素.md）闭环且无硬编码色值回潮；
- 数据表设计约定独立于系统级技术标准/规范的边界，在 CLAUDE.architect.md、tech-common-rules、data-model、04 模板、交接索引模板五处表述一致；
- 「不设项目级技术通用规则」口径在 CLAUDE.architect.md（4 处）、tech-common-rules、AGENTS.architect、项目级技术摘要模板、交接索引模板中一致（均为否定式声明，无实质残留）。
