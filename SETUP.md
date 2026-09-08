# Software Engineering Agent 安装与配置

## 前置要求

> 以下 Pencil 相关依赖**仅在需要原型生成（第二部分）时才需要**。仅做需求分析（第一部分）无需安装。

1. **Pencil 桌面应用**（原型生成时需要，必须已安装并运行）
   - 下载地址：https://pencil.evolus.vn/
   - 运行后保持打开状态，否则 MCP 调用会失败

2. **Pencil MCP Server**（原型生成时需要）
   - **OpenCode 宿主**：无需额外安装，Pencil.app 桌面端内置 MCP server 二进制（详见下方「配置步骤」）
   - **Claude Code 宿主**：需确保 `pencil-mcp` 命令可用（随 Pencil 桌面应用安装，或参考 Pencil 官方文档）

## 配置步骤

### 在 OpenCode 中使用

1. 将本项目克隆或复制到本地
2. 在 OpenCode 中打开本项目目录
3. **（重要）Pencil MCP 已默认启用**：`opencode.json` 中 `mcp.pencil` 已配置为 `enabled: true`、`type: "local"`，command 直接指向 Pencil.app 桌面端内置的 MCP server 二进制（`/Applications/Pencil.app/Contents/Resources/app.asar.unpacked/out/mcp-server-darwin-arm64 --app desktop openCodeCLI`）。只需确保 Pencil 桌面应用已安装并保持运行即可，无需手动修改配置
4. 在对话中输入 `prototype-agent` 切换为「需求分析」Agent（或通过 Tab 键选择）
5. 开始对话：「我想设计一个电商 App 原型」
6. 如需做技术架构设计，切换为 `architect-agent`：输入 `architect-agent` 或在 Tab 选择；其指令见 `CLAUDE.architect.md` / `AGENTS.architect.md`，技术产物写入系统的 `tech/` 子目录

### 在 Claude Code 中使用

1. 将本项目克隆或复制到本地
2. 将 `claude.json` 中的 MCP 配置合并到你的 `~/.claude/settings.json` 中
   ```json
   // ~/.claude/settings.json
   {
     "mcpServers": {
       "pencil": {
         "command": "pencil-mcp",
         "args": []
       }
     }
   }
   ```
   说明：Claude Code 宿主通过 `pencil-mcp` 命令调用（需单独安装 Pencil MCP Server）；OpenCode 宿主则直接使用 Pencil.app 内置二进制（见上文）。二者启动方式不同，按各自宿主配置即可
3. 在 Claude Code 中打开本项目目录
4. 开始对话，CLAUDE.md 会自动加载

### 在 Cursor 中使用

1. 将 `claude.json` 复制为 `.cursor/mcp.json`
2. 项目级指令由 CLAUDE.md 自动加载

## 使用方法

### 启动一个任务

1. 在 AI 对话中输入你想设计的需求，例如：「我想设计一个电商 App」
2. Agent 会通过双段式工作流与你协作：
   - **第一部分 · 需求分析（必做）**
     - **阶段 1**：了解系统架构（定位、场景、模块骨架、角色、UI 风格）→ 确认
     - **阶段 2**：逐模块沟通详细规格 → 逐模块确认
     - 产出并确认「需求包」（系统要求规范.md + 系统交互规范.md + modules/*/01-*.md + modules/*/02-*.md + 项目级通用规则）
   - **决策门禁（需求包确认后触发）**：询问后续环节，三选一
     - ① 原型设计（Pencil 方案，可选）→ 提示打开本地 Pencil 桌面应用并确保 Pencil MCP 服务已启动，进入第二部分
     - ② 技术分析智能体（architect-agent）→ 基于需求包生成/更新技术设计（模块级 03-技术规格 / 04-数据模型）
     - ③ 结束 → 流程结束（prd-系统结果摘要.md 已随需求包定稿生成、prd-系统操作记录.md 已追加、项目级产品摘要.md 已刷新）
   - **第二部分 · 原型生成（可选）**：自动调用 Pencil 绘制 → 截图自校验 → 通知你验收
3. 所有产出文件都在 `document/{项目名}/` 下：项目级文件（项目级产品摘要.md、通用异常处理.md、通用校验规则.md）在 `{项目名}/`；系统级文件（系统要求规范.md、系统交互规范.md、modules/*/01-*.md、modules/*/02-*.md、prd-系统结果摘要.md、prd-系统操作记录.md，以及可选的原型文件、截图、校验报告）在 `{项目名}/{系统名}/` 下

> 工程链路：本 agent 产出「需求包」（上游产品功能基础说明）→ 技术分析智能体（architect-agent） 生成功能设计文件 → 编程智能体 生成代码。需求包归属于某项目（`document/{项目名}/`），并由项目级通用规则（`通用异常处理.md` + `通用校验规则.md`）统一约束跨系统通用规则；需求包始终可被下游独立消费；Pencil 原型仅为可选的视觉化辅助。

### 架构说明

**新架构（v2.0，当前默认）**：三层架构（项目/系统/模块）

- **优势**：Token 优化 78%，文档模块化，通用规则复用
- **目录结构**：
  ```
document/{项目名}/
├── 项目级产品摘要.md
├── 通用异常处理.md（项目级通用异常）
├── 通用校验规则.md（项目级通用校验）
  └── {系统名}/
      ├── prd/
      │   ├── 系统要求规范.md
      │   ├── 系统交互规范.md（系统级交互规范）
      │   └── modules/{模块名}/
      │       ├── 01-{模块名}-需求规格.md
      │       └── 02-{模块名}-UI交互规格.md
      └── tech/
  ```

### 使用自定义 UI 设计要素

可以将你的品牌 UI 设计要素文件放入系统目录中，Agent 会在原型生成（第二部分）时自动使用它：

```bash
# 在系统开始前或原型生成之前
# 将你自定义的 界面设计要素.md 放入 document/{项目名}/{系统名}/prd/
# Agent 在第二部分会优先使用自定义文件，否则使用模板
```

### 系统归属说明

系统产物永久归属于其项目目录 `document/{项目名}/{系统名}/`，无需手动归档；项目级已天然承担组织与隔离职责。

---

## 项目文件清单

```
software-engineering-agent/
├── CLAUDE.md                    # 需求分析智能体（prototype-agent） 项目级指令（自动加载）
├── CLAUDE.architect.md          # 技术分析智能体（architect-agent） 项目级指令（architect-agent 加载）
├── AGENTS.md                    # 需求分析智能体（prototype-agent） 对话策略
├── AGENTS.architect.md          # 技术分析智能体（architect-agent） 对话策略
├── opencode.json                # OpenCode 配置（注册 prototype-agent + architect-agent + Pencil MCP）
├── claude.json                  # Claude Code MCP 配置（仅 MCP；双智能体指令文件注册见 opencode.json，二者职责不同）
├── agent/
│   ├── prototype-agent.md       # 需求分析智能体（prototype-agent） 定义
│   └── architect-agent.md       # 技术分析智能体（architect-agent） 定义
├── skills/
│   ├── business-architecture/  # 产品阶段1：系统架构沟通
│   │   └── SKILL.md
│   ├── page-specs/             # 产品阶段2：逐模块规格沟通
│   │   └── SKILL.md
│   ├── pencil-executor/        # 产品第二部分：原型生成（Pencil）+ 自校验闭环
│   │   └── SKILL.md
│   ├── delivery/               # 产品：系统结果摘要 + 系统操作记录 + 项目级产品摘要
│   │   └── SKILL.md
│   ├── tech-common-rules/      # 技术阶段0：系统级技术标准确认
│   │   └── SKILL.md
│   ├── spec-analysis/          # 技术阶段1：需求解析
│   │   └── SKILL.md
│   ├── tech-architecture/      # 技术阶段2：技术规格（需求翻译器 / 中转站）
│   │   └── SKILL.md
│   ├── data-model/             # 技术阶段3：业务表结构
│   │   └── SKILL.md
│   ├── self-check/             # 门禁前一致性自检（FR-x 追溯 / 场景覆盖 / 章节号一致性）
│   │   └── SKILL.md
│   └── tech-delivery/          # 技术：技术结果摘要 + 项目级技术摘要 + 交接索引
│       └── SKILL.md
├── templates/
│   ├── 界面设计要素.md                # UI 设计要素模板
│   ├── 交接索引.md                   # 交接索引模板（编程智能体清单）
│   ├── prototype-agent/              # 产品侧模板
│   │   ├── project-level/            # 项目级
│   │   │   ├── 项目级产品摘要.md       # 项目级产品摘要模板（索引式·轻）
│   │   │   ├── 通用异常处理.md         # 项目级通用异常模板
│   │   │   └── 通用校验规则.md         # 项目级通用校验模板
│   │   ├── system-level/             # 系统级
│   │   │   ├── 系统要求规范.md         # 系统级要求规范模板（系统定义 + 场景 + 角色权限 + 模块清单，模板名 = 产物名）
│   │   │   ├── 系统交互规范.md         # 系统级交互规范模板（组件交互行为标准）
│   │   │   ├── prd-系统结果摘要.md     # 产品系统结果摘要模板
│   │   │   └── prd-系统操作记录.md     # 产品系统操作记录模板
│   │   └── module-level/             # 模块级
│   │       ├── 01-模块-需求规格.md     # 模块需求规格模板
│   │       └── 02-模块-UI交互规格.md   # 模块UI交互规格模板
│   └── architect-agent/              # 技术侧模板
│       ├── project-level/
│       │   └── 项目级技术摘要.md       # 项目级技术摘要模板（索引式·轻）
│       ├── system-level/             # 系统级
│       │   ├── 系统级技术标准.md       # 系统级固化配置定义模板
│       │   ├── 系统级技术规范.md       # 系统级技术目标模板
│       │   ├── 数据表设计约定.md       # 数据表设计规范模板（独立）
│       │   ├── 模块间接口依赖清单.md   # 跨模块关系导航模板
│       │   ├── tech-系统结果摘要.md    # 技术系统结果摘要模板
│       │   └── tech-系统操作记录.md    # 技术系统操作记录模板
│       └── module-level/             # 模块级
│           ├── 03-模块-技术规格.md     # 模块技术规格模板（模块→功能点两层 + 接口内联）
│           └── 04-模块-数据模型.md     # 模块数据模型模板（从 03 派生）
├── document/                     # 系统根目录（自动创建）
│   └── {项目名}/                 # 项目目录（按业务归属）
│       ├── 项目级产品摘要.md        # 产品级系统索引
│       ├── 项目级技术摘要.md        # 技术级系统索引
│       ├── 通用异常处理.md        # 项目级通用异常
│       ├── 通用校验规则.md        # 项目级通用校验
│       └── {系统名}/              # 系统目录（可独立交付的子系统）
│           ├── 系统说明.md        # 系统基本信息
│           ├── prd/              # 产品产物子目录（prototype-agent 独占）
│           │   ├── 系统要求规范.md
│           │   ├── 系统交互规范.md   # 系统级交互规范
│           │   ├── modules/      # 模块目录
│           │   │   └── {模块名}/
│           │   │       ├── 01-{模块名}-需求规格.md
│           │   │       └── 02-{模块名}-UI交互规格.md
│           │   ├── prd-系统结果摘要.md
│           │   ├── prd-系统操作记录.md
│           │   ├── 界面设计要素.md（可选）
│           │   ├── 原型执行日志.md（可选）
│           │   ├── screenshots/（可选）
│           │   ├── screenshots-reviewed/（可选）
│           │   ├── 校验报告.md（可选）
│           │   ├── 交付摘要.md（可选）
│           │   └── {system_name}.pen（可选）
│           ├── tech/             # 技术产物子目录（architect-agent 独占）
│           │   ├── 系统级技术标准.md
│           │   ├── 系统级技术规范.md
│           │   ├── 数据表设计约定.md
│           │   ├── modules/      # 模块级设计
│           │   │   └── {模块名}/
│           │   │       ├── 03-{模块名}-技术规格.md
│           │   │       └── 04-{模块名}-数据模型.md
│           │   ├── 模块间接口依赖清单.md
│           │   ├── tech-系统结果摘要.md
│           │   └── tech-系统操作记录.md
│           └── 交接索引.md        # 同系统 prd/tech 产物汇总
├── docs/                         # 文档目录（活文档）
│   ├── 快速启动指南.md
│   └── 最佳实践.md
├── archive/                      # 过程文档归档（审计报告/优化记录/分析记录；命名=日期+工具名，规范见 archive/README.md）
│   ├── README.md                 # 归档规范
│   └── {YYYY-MM-DD}_{工具名}_{文档名}.md（历史过程文档）
├── scripts/                      # 脚本目录
│   ├── README.md
│   ├── session-state.sh
│   ├── context-recovery-check.sh
│   ├── consistency-check.sh
│   ├── validate-docs.sh
│   └── pre-commit.sample
├── README.md                     # 本项目说明
└── SETUP.md                      # 本文件（配置说明）
```

## 架构优势

### Token 优化（↓78%）

**旧架构**：修改单个页面需要读取完整的 01/02 大文件（~15000 tokens）
**新架构**：仅需读取 系统要求规范 + 系统交互规范 + 目标模块的 01/02（~3200 tokens）

### 文档模块化

- **系统级**：系统要求规范.md（系统定位 + 场景 + 模块骨架）+ 系统交互规范.md（组件交互行为标准）
- **项目级通用**：通用异常处理.md / 通用校验规则.md（跨系统复用）
- **模块级**：modules/*/01-*.md（需求规格）+ modules/*/02-*.md（UI规格）

### 维护成本降低（↓50%）

- 无架构兼容负担
- 无双轨维护
- 术语统一（项目/系统/模块）
- 修改影响范围小（单模块 480 行 vs 全部 2200 行）

## 更新日志

- **2026-09-07**：独立审计 + 三批修复（P0×3 / P1×6 / P2×11）——docs/ 两份活文档按新架构重写、FR-x 编号口径统一（方案 A）、六维确认收敛、03/04 相对路径修正、01 模板补用户故事、consistency-check 防线增强、连带清理旧术语/悬空编号。详见 `archive/2026-09-07_workbuddy_独立审计报告.md`。
- **2026-09-04**：架构升级（v2.0）——完全移除旧架构支持，统一为三层架构（项目/系统/模块）。Token 优化 78%，维护成本降低 50%。详见 `archive/2026-09-04_claude_phase3-final-report.md`。
- **2026-09-02**：质量优化专项（8.8 → 9.0+）——完成 12 项优化，新增 scripts/ 和 docs/ 目录。详见 `archive/2026-09-02_claude_优化实施报告.md`。
