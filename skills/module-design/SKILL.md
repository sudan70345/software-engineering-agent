---
name: module-design
description: 针对复杂/核心模块的详细设计（时序图/领域模型/状态流转/关键规则算法），生成 tech/06-module-design.md（可选阶段，简单 CRUD 可跳过）。门禁5（可跳过）。
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# 模块详细设计 Skill — 阶段 5（可选）

## 输入
- `tech/03`~`tech/05`（已确认）

## 输出
- `tech/06-module-design.md`（结构见 `templates/module-design.md`）

## 触发条件
- 存在复杂度高的模块（多表多接口协同 / 重要算法 / 复杂状态机 / 分布式事务）。
- 否则跳过本阶段，直接进入 tech-delivery。

## 工作流程
- 选取目标模块，给出时序图、领域模型/状态机、关键规则与算法、异常与回滚。
- 写出 06（可选确认门禁5：若编写则展示确认；若跳过则在 `tech/任务操作记录.md` 注明"模块设计不适用"）。
- 记录追加。
