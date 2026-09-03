# 会话状态管理脚本

本目录包含用于会话上下文管理和恢复的辅助脚本。

## 脚本清单

### 1. session-state.sh — 会话状态快照

**用途**：在关键门禁点生成会话状态快照，记录当前工程、任务、阶段信息。

**使用场景**：
- 完成阶段 1（业务架构沟通）后
- 完成阶段 2（逐页面详细沟通）后
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
- 切换工程/任务时
- 不确定当前上下文是否完整时

**命令**：
```bash
./scripts/context-recovery-check.sh
```

**检查项**：
- ✅ R1: 工程名与任务目录是否存在
- ✅ R2: 工程级双文件（产品工程摘要.md + 产品通用规则.md）是否存在
- ✅ R3: 当前任务上下文（需求规格、结果摘要、当前阶段）
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
#    - 扫描 document/ 下工程列表
#    - 读取目标工程的 产品工程摘要.md + 产品通用规则.md
#    - 确定任务目录后，读取结果摘要和操作记录
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

**用途**：检查需求包（01-需求规格说明书.md + 02-UI交互规格说明书.md）的完整性和一致性。

**使用场景**：
- 手动校验需求包质量
- Pre-commit hook（自动化）
- CI pipeline 集成

**命令**：
```bash
# 自动扫描最新任务并校验
./scripts/validate-docs.sh

# 校验指定任务
./scripts/validate-docs.sh --task-dir document/{工程名}/{任务名}_{YYYYMMDD}/

# 严格模式（警告也视为失败）
./scripts/validate-docs.sh --strict
```

**检查项**：
- ✅ 必要文件存在性（01/02/结果摘要/操作记录）
- ✅ FR-x 编号连续性（FR-1、FR-2、...，无跳号）
- ✅ 场景[Sx] 编号连续性（场景[S1]、场景[S2]、...）
- ✅ 页面[N] 与 02 §4 一致性（总览清单与实际章节对齐）
- ✅ FR-x 的输入/输出/校验/异常完整性（§10-§13 存在）
- ✅ 版本号一致性（01 与 02 版本号相同）
- ✅ 职责边界（禁止接口定义/数据模型/技术选型）

**退出码**：
- `0`: 校验通过或仅有警告（非严格模式）
- `1`: 校验失败

### 4. pre-commit.sample — Git Pre-commit Hook

**用途**：在 git commit 前自动校验需求包文档，阻止不完整文档提交。

**安装**：
```bash
# 一次性安装（复制到 .git/hooks/ 并添加执行权限）
cp scripts/pre-commit.sample .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

**工作机制**：
1. 检测本次提交是否包含 01-需求规格说明书.md 或 02-UI交互规格说明书.md
2. 如果包含，自动运行 `validate-docs.sh` 校验
3. 校验失败则阻止提交，并提示修复建议
4. 校验通过则允许提交

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

# 2. 正常提交（hook 会自动校验）
git add document/{工程名}/{任务名}_{YYYYMMDD}/prd/*.md
git commit -m "完成需求包 v1.0"

# 3. 如果校验失败，修复后重新提交
```

## 未来扩展

- [ ] 自动从快照文件恢复上下文（生成 agent 可读的恢复提示）
- [ ] 与 AGENTS.md 的确认门禁集成（门禁通过时自动快照）
- [ ] 支持多会话并行管理（不同工程/任务的快照隔离）
- [x] CI 级自动化校验（pre-commit hook 检查文档一致性）✅ 已完成
