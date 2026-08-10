# ADR-004: solar-harness 采用逐特性迁移，不做整仓合并

## 状态

Accepted as a migration guardrail; phase 1 source inventory released

## 背景

目标分支已包含成熟的 Harness、运行和研究功能。`<user-fork>/solar-harness` 同时包含已推送能力、未完成工作、重复实现、机器配置、运行 artifacts 和潜在私密信息。整仓 merge 无法建立可靠的功能级证据。

## 决策

- 用户已于 2026-08-10 允许盘点已推送部分；操作前必须固定 source SHA，先输出 machine-readable import manifest；
- 2026-05-20 至 2026-07-20 的未完成工作单独进入第二阶段候选池，未经单项选择不得导入；
- 每项特性单独分类、映射、测试、移植和 PR；
- 每项特性必须路由到 AI4Research 或独立的 GenesisPod，不允许模糊双写；
- 优先 adapter/plugin/capsule，不覆盖调度核心；
- 记录来源 SHA、许可证、changed files、acceptance evidence 与 rollback；
- 运行 artifacts、secret 和机器路径不迁入源码仓。

## 备选方案

| 方案 | 优点 | 缺点 |
|---|---|---|
| 整仓 merge | 表面速度快 | 冲突大、重复实现、隐私与状态污染难审计 |
| Git subtree 永久同步 | 保留独立历史 | 两边目录重叠，ownership 不清 |
| 手工复制无 manifest | 灵活 | 无来源、无回滚、不可复核 |

## 后果

- 正向：风险和证据按功能隔离；
- 负向：迁移速度较慢；
- 缓解：先自动生成 inventory/diff，批量识别已存在功能。

## 复审触发

源仓清理完成且证明与目标 `harness/` 有共同可线性合并的历史。
