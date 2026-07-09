# Software Engineering Agent 安装与配置

## 前置要求

> 以下 Pencil 相关依赖**仅在需要原型生成（第二部分）时才需要**。仅做需求分析（第一部分）无需安装。

1. **Pencil 桌面应用**（原型生成时需要，必须已安装并运行）
   - 下载地址：https://pencil.evolus.vn/
   - 运行后保持打开状态，否则 MCP 调用会失败

2. **Pencil MCP Server**（原型生成时需要，必须已安装）
   - 安装方式：`npm install -g @pencil/mcp-server`（或参考 Pencil 官方文档）

## 配置步骤

### 在 OpenCode 中使用

1. 将本项目克隆或复制到本地
2. 在 OpenCode 中打开本项目目录
3. **（重要）激活 Pencil MCP 服务**：编辑 `opencode.json`，将 `mcp.pencil.enabled` 从 `false` 改为 `true`
   ```json
   "pencil": {
     "type": "stdio",
     "command": "pencil-mcp",
     "args": [],
     "enabled": true   // ← 改为 true
   }
   ```
   确保命令行中 `pencil-mcp` 命令可用（已安装 Pencil MCP Server）
4. 在对话中输入 `prototype-agent` 切换为「需求分析」Agent（或通过 Tab 键选择）
5. 开始对话：「我想设计一个电商 App 原型」
6. 如需做技术架构设计，切换为 `architect-agent`：输入 `architect-agent` 或在 Tab 选择；其指令见 `CLAUDE.architect.md` / `AGENTS.architect.md`，技术产物写入任务的 `tech/` 子目录

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
     - **阶段 1**：了解业务架构（端、类型、页面、流程、风格）→ 确认
     - **阶段 2**：逐页面沟通详细规格 → 逐页确认
     - 产出并确认「需求包」（01 + 02）
   - **决策门禁（需求包确认后触发）**：询问是否继续后续任务（当前仅「原型生成（Pencil 方案）」）
     - 拒绝 → 流程结束（任务结果摘要.md 已随需求包定稿生成、任务操作记录.md 已追加、产品工程摘要.md 已刷新）。
     - 同意 → 提示打开本地 Pencil 桌面应用并确保 Pencil MCP 服务已启动，进入第二部分
   - **第二部分 · 原型生成（可选）**：自动调用 Pencil 绘制 → 截图自校验 → 通知你验收
3. 所有产出文件（业务架构描述、页面规格、任务结果摘要.md、任务操作记录.md、产品工程摘要.md，以及可选的原型文件、截图、校验报告）都在 `document/{工程名}/{任务名}_{YYYYMMDD}/` 目录下（归属于对应工程项目）

> 工程链路：本 agent 产出「需求包」（上游产品功能基础说明）→ 技术分析智能体（architect-agent） 生成功能设计文件 → 编程智能体 生成代码。需求包归属于某工程项目（`document/{工程名}/`），并由 `产品通用规则.md` 统一约束跨任务通用规则；需求包始终可被下游独立消费；Pencil 原型仅为可选的视觉化辅助。

### 使用自定义 UI 设计要素

可以将你的品牌 UI 设计要素文件放入任务目录中，Agent 会在原型生成（第二部分）时自动使用它：

```
# 在任务开始前或原型生成之前
将你自定义的 ui-design-elements.md 放入 document/{工程名}/{任务名}_{YYYYMMDD}/
# Agent 在第二部分会优先使用自定义文件，否则使用模板
```

### 任务归属说明

任务产物永久归属于其工程项目目录 `document/{工程名}/{任务名}_{YYYYMMDD}/`，无需手动归档；工程级已天然承担组织与隔离职责。

---

## 项目文件清单

```
software-engineering-agent/
├── CLAUDE.md                    # 需求分析智能体（prototype-agent） 项目级指令（自动加载）
├── CLAUDE.architect.md          # 技术分析智能体（architect-agent） 项目级指令（architect-agent 加载）
├── AGENTS.md                    # 需求分析智能体（prototype-agent） 对话策略
├── AGENTS.architect.md          # 技术分析智能体（architect-agent） 对话策略
├── opencode.json                # OpenCode 配置（注册 prototype-agent + architect-agent）
├── claude.json                  # Claude Code MCP 配置
├── agent/
│   ├── prototype-agent.md       # 需求分析智能体（prototype-agent） 定义
│   └── architect-agent.md       # 技术分析智能体（architect-agent） 定义
├── skills/
│   ├── business-architecture/  # 产品阶段1：业务架构沟通
│   │   └── SKILL.md
│   ├── page-specs/             # 产品阶段2：逐页面规格沟通
│   │   └── SKILL.md
│   ├── pencil-executor/        # 产品第二部分：原型生成（Pencil）+ 自校验闭环
│   │   └── SKILL.md
│   ├── delivery/               # 产品：任务结果摘要 + 任务操作记录 + 产品工程摘要
│   │   └── SKILL.md
│   ├── spec-analysis/          # 技术阶段1：需求解析
│   │   └── SKILL.md
│   ├── tech-architecture/      # 技术阶段2：技术架构
│   │   └── SKILL.md
│   ├── data-model/             # 技术阶段3：业务表结构
│   │   └── SKILL.md
│   ├── api-design/             # 技术阶段4：接口规划
│   │   └── SKILL.md
│   ├── module-design/          # 技术阶段5（可选）：模块详细设计
│   │   └── SKILL.md
│   └── tech-delivery/          # 技术：技术结果摘要 + 技术工程摘要 + 交接索引
│       └── SKILL.md
├── templates/
│   ├── ui-design-elements.md           # UI 设计要素模板
│   ├── 产品工程摘要.md                   # 产品工程摘要模板（索引式·轻）
│   ├── 技术工程摘要.md                   # 技术工程摘要模板（索引式·轻）
│   ├── 任务结果摘要.md                   # 产品任务结果摘要模板
│   ├── 任务操作记录.md                   # 产品任务操作记录模板
│   ├── 技术通用规则.md            # 技术通用规则模板（新建工程复制为 技术通用规则.md）
│   ├── 产品通用规则.md         # 产品通用规则模板
│   ├── tech-architecture.md            # 技术架构模板（03）
│   ├── data-model.md                   # 业务表结构模板（04）
│   ├── api-design.md                   # 接口规划模板（05）
│   ├── module-design.md                # 模块详细设计模板（06，可选）
│   ├── tech-任务结果摘要.md             # 技术任务结果摘要模板
│   ├── tech-任务操作记录.md             # 技术任务操作记录模板
│   └── 交接索引.md                      # 交接索引模板（编程智能体清单）
├── document/                   # 任务根目录（自动创建）
│   ├── {工程名}/                # 工程项目目录（按业务归属）
│   │   ├── 产品通用规则.md       # 产品级公共规则
│   │   ├── 技术通用规则.md          # 技术级公共规则（architect-agent 维护）★新增
│   │   ├── 产品工程摘要.md                # 产品级任务索引 ★改名
│   │   ├── 技术工程摘要.md                # 技术级任务索引 ★新增
│   │   └── {任务名}_{YYYYMMDD}/
│   │       ├── prd/                  # 产品产物子目录（prototype-agent 独占）
│   │       │   ├── 01-business-architecture.md
│   │       │   ├── 02-page-specs.md
│   │       │   └── 任务结果摘要.md / 任务操作记录.md
│   │       ├── tech/                     # 技术产物子目录（architect-agent 独占）★新增
│   │       │   ├── 03-tech-architecture.md
│   │       │   ├── 04-data-model.md
│   │       │   ├── 05-api-design.md
│   │       │   ├── 06-module-design.md（可选）
│   │       │   ├── 任务结果摘要.md
│   │       │   └── 任务操作记录.md
│   │       └── 交接索引.md               # 同任务 prd/tech 产物汇总 ★新增
└── SETUP.md                     # 本文件（配置说明）
```
