# 会话状态管理脚本

本目录包含用于会话上下文管理和恢复的辅助脚本。

## 脚本清单

### 1. session-state.sh — 会话状态快照

**用途**：在关键门禁点生成会话状态快照，记录当前项目、系统、阶段信息。

**使用场景**：
- 完成阶段 1（系统架构沟通）后
- 完成阶段 2（逐模块详细沟通）后
- 完成需求包定稿后
- 完成技术规格说明书后
- 任何希望保存当前进度的时刻

**命令**：
```bash
# 保存当前会话状态
./scripts/session-state.sh save

# 列出最近的快照
./scripts/session-state.sh list
```

**输出位置**：`.session_state/snapshot_YYYYMMDD_HHMMSS.json`

### 2. context-recovery-check.sh — 上下文恢复自检

**用途**：会话恢复时快速检查必要上下文是否加载完整。

**使用场景**：
- 长时间中断后恢复会话
- 上下文压缩后重新开始
- 切换项目/系统时
- 不确定当前上下文是否完整时

**命令**：
```bash
./scripts/context-recovery-check.sh
```

**检查项**：
- ✅ R1: 项目名与系统目录是否存在
- ✅ R2: 项目级文件（项目级产品摘要.md + 通用异常处理.md + 通用校验规则.md）是否存在
- ✅ R3: 当前系统上下文（系统要求规范、系统交互规范、模块级 01/02、系统结果摘要、当前阶段）
- ✅ R4: 会话状态快照是否可用

**退出码**：
- `0`: 上下文完整或仅有警告
- `1`: 上下文缺失关键信息，需执行恢复流程

## 典型工作流

### 会话中断前
```bash
# 保存当前状态快照
./scripts/session-state.sh save
```

### 会话恢复后
```bash
# 1. 检查上下文完整性
./scripts/context-recovery-check.sh

# 2. 如果检查失败，按提示执行恢复流程：
#    - 扫描 document/ 下项目列表
#    - 读取目标项目的 项目级产品摘要.md + 通用异常处理.md + 通用校验规则.md
#    - 确定系统目录后，读取结果摘要和操作记录
```

## 与 CLAUDE.md 的关系

这些脚本是 `CLAUDE.md §上下文恢复检查点` 的自动化实现：

- **手动流程**（CLAUDE.md 定义）：agent 在会话恢复时按 R1-R4 流程逐步确认
- **自动化辅助**（本脚本）：快速检查并给出恢复提示，减少人工判断成本

**建议使用方式**：
1. 会话恢复时先运行 `context-recovery-check.sh`
2. 根据检查结果决定是否需要执行完整的 R1-R4 流程
3. 在关键门禁点执行 `session-state.sh save` 以便后续快速恢复

### 3. validate-docs.sh — 文档一致性校验

**用途**：检查需求包（系统级 系统要求规范 + 系统交互规范 + 模块级 01/02）的完整性和一致性。

**使用场景**：
- 手动校验需求包质量（本地自检 document/ 下的产物）
- CI pipeline 集成
- ⚠️ 注意：document/ 已被 .gitignore 忽略（不进版本控制），本脚本**不用于** git pre-commit（pre-commit 检测不到被忽略文件的变更）

**命令**：
```bash
# 自动扫描最新系统并校验
./scripts/validate-docs.sh

# 校验指定系统
./scripts/validate-docs.sh --system-dir document/{项目名}/{系统名}/

# 严格模式（警告也视为失败）
./scripts/validate-docs.sh --strict
```

**检查项**：
- ✅ 必要文件存在性（系统要求规范 / 系统交互规范 / 系统结果摘要 / 系统操作记录）
- ✅ 模块 01/02 文件成对存在
- ✅ FR-x 编号连续性（模块内 FR-1、FR-2、...，无跳号）
- ✅ 场景[Sx] 编号连续性（场景[S1]、场景[S2]、...）
- ✅ 01 章节完整性（§5 输入 / §6 输出 / §7 校验 / §9 异常）
- ✅ 版本号一致性（同模块 01 与 02 版本号相同）
- ✅ 职责边界（禁止接口定义/数据模型/技术选型）

**退出码**：
- `0`: 校验通过或仅有警告（非严格模式）
- `1`: 校验失败

### 4. pre-commit.sample — Git Pre-commit Hook

**用途**：在 git commit 前自动校验「进版本控制的骨架文件」（主指令 / skills / templates / opencode.json），阻断多文件同步漂移。

**安装**：
```bash
# 一次性安装（复制到 .git/hooks/ 并添加执行权限）
cp scripts/pre-commit.sample .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

**工作机制**：
1. 运行 `consistency-check.sh` 全仓一致性校验（5 项：opencode.json 合法 / skill 软链接 / 术语引用可解析 / 章节号不变量 / 禁用旧术语）
2. 校验失败则阻止提交，并提示修复建议
3. 校验通过则允许提交

> ⚠️ 本 hook **不校验** `document/` 下的需求包（document/ 已被 .gitignore 忽略）。需求包完整性请用 `validate-docs.sh` 手动或 CI 校验。

**临时跳过**：
```bash
# 如需临时跳过校验（不推荐）
git commit --no-verify
```

## 典型工作流（更新）

### 会话中断前
```bash
# 1. 保存当前状态快照
./scripts/session-state.sh save

# 2. 校验文档完整性（可选）
./scripts/validate-docs.sh
```

### 会话恢复后
```bash
# 1. 检查上下文完整性
./scripts/context-recovery-check.sh

# 2. 如果检查失败，按提示执行恢复流程
```

### Git 提交前
```bash
# 1. 安装 pre-commit hook（仅需一次）
cp scripts/pre-commit.sample .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# 2. 正常提交骨架文件（hook 会自动做全仓一致性校验）
git add CLAUDE.md skills/ templates/ opencode.json
git commit -m "refactor: 对齐骨架文件术语与章节结构"

# 3. 如果校验失败，修复后重新提交
```

> 📌 `document/` 下的需求包已由 .gitignore 忽略，不进入版本控制；提交前如需校验其完整性，手动运行 `./scripts/validate-docs.sh`。

## 未来扩展

- [ ] 自动从快照文件恢复上下文（生成 agent 可读的恢复提示）
- [ ] 与 AGENTS.md 的确认门禁集成（门禁通过时自动快照）
- [ ] 支持多会话并行管理（不同项目/系统的快照隔离）
- [x] 自动化校验（pre-commit hook 做全仓骨架一致性校验）✅ 已完成
