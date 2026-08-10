# ADR-002: Harness 为 canonical runtime，Core 通过契约演进

## 状态

Proposed

## 背景

当前 `harness/` 已实现完整 Requirement/TaskGraph/operator/evidence 路径；`core/` 同时存在 daemon、scheduler 与 orchestrator，但仓库说明其部分模块仍是 compatibility/scaffold。让两套运行时同时拥有状态语义会持续产生漂移。

## 决策

- `harness/` 在当前 RC 周期内拥有 canonical runtime semantics；
- `core/` 通过版本化 CLI/API/schema 调用或读取 Harness；
- `core/` 不新建权威 TaskGraph、gate 或 evidence 状态；
- 新领域能力优先做 plugin/capsule/adapter；
- 只有在 parity suite 证明等价后，才可通过新 ADR 转移某项 ownership。

## 备选方案

| 方案 | 优点 | 缺点 |
|---|---|---|
| 立即 TypeScript 重写 | 类型与单语言工具链 | 高回归风险，RC 延期，证据语义难复刻 |
| 两套长期并行 | 可独立试验 | 双事实源、状态 reconciliation 成本高 |
| 停止 Core | 简单 | 丢失可选 daemon/UI 演进价值 |

## 后果

- 正向：保留现有可用路径，限制新漂移；
- 负向：短期仍维护两种语言和 adapter；
- 缓解：architecture boundary gate + parity tests。

## 复审触发

Core 完成 Requirement、graph、operator、gate、evidence、closure 的确定性 parity suite。
