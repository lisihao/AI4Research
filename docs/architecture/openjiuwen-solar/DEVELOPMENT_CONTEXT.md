# Solar 开发语境

状态：Active

日期：2026-08-10

本文件是 Solar 相关开发的项目边界与迁移路由事实源。若其他文档与本文件冲突，先按本文件执行，再通过 ADR 修正文档。

## 1. 项目边界

| 项目 | 主线 | 角色 | 边界 |
|---|---|---|---|
| `Stellven/AI4Research` | `openJiuwen-Solar` | Solar 唯一主仓与集成主干 | 承接 Solar runtime、Harness、agent、research 与平台能力 |
| `<user-fork>/GenesisPod` | fork 的受控开发分支 | 独立的洞察分析与报告平台 | 不是 AI4Research 的 UI、子目录、子模块或部署壳 |
| `<user-fork>/solar-harness` | 固定 source SHA | 特性来源仓 | 不是目标主仓；只按特性向两个目标项目迁移 |

`/Users/sihaoli/Projects/Solar` 继续作为独立项目存在，但不是本计划的 AI4Research 工作区，也不自动成为迁移来源。

## 2. 机器职责

| 机器 | 职责 | 禁止事项 |
|---|---|---|
| MacBook | 两个项目的日常开发、Codex、测试、提交、PR、部署发起与监控 | 不长期运行生产式后台服务 |
| Mac mini | AI4Research 与 GenesisPod 的固定 SHA 运行、任务执行、日志、状态、证据和回滚 | 不手工开发，不把运行状态提交回 Git |

Mac mini 上两个项目必须使用独立的 release、配置、secret、状态、日志、launchd label 和端口空间。

## 3. 第一阶段：已推送特性迁移

用户已于 2026-08-10 释放“已推送部分”的盘点与迁移门禁。

### 3.1 迁入 AI4Research

- 对 `<user-fork>/solar-harness` 已推送且可固定 SHA 的功能做只读 inventory；
- 将 runtime、Harness、agent、research、调度、证据、部署与平台类能力映射到 `openJiuwen-Solar`；
- 目标已有的能力只补行为差异和测试，不重复复制；
- 每个特性独立 contract、分支、测试、提交/PR 和回滚记录。

### 3.2 迁入 GenesisPod

- 大咖/创作者洞察；
- Hugging Face 模型、作者与趋势洞察；
- GitHub 项目、开发者与趋势洞察；
- YouTube 大咖、频道与内容洞察；
- 相关采集、分析、证据、报告与产品工作流。

这些能力进入 GenesisPod 自己的领域模型、任务、存储、API 和页面，不把 GenesisPod 嵌入 AI4Research。

## 4. 第二阶段：未完成特性治理

范围是 2026-05-20 至 2026-07-20 在 `solar-harness` 中持续开发、尚未完成的候选特性。

执行顺序：

```text
固定 source SHA 和时间范围
  -> 建立候选清单
  -> 逐项判断价值、完成度、重复度和风险
  -> 用户/产品门禁选中单项
  -> 补齐 contract 与测试
  -> 在目标仓重新开发或最小移植
  -> 全量门禁
  -> 独立提交/PR/部署/回滚证据
```

第二阶段禁止整仓 merge、整目录覆盖和一次性导入全部未完成代码。

## 5. 特性路由规则

| 特性类型 | 默认目标 |
|---|---|
| Scheduler、operator、agent runtime、evidence、research infrastructure | AI4Research |
| 洞察采集、趋势分析、人物/项目画像、报告产品工作流 | GenesisPod |
| 两边都需要的协议或算法 | 先定义版本化 contract；分别实现 adapter，避免共享可变运行时 |
| 日志、缓存、数据库、token、机器路径、历史运行 artifact | 不进入任何源码仓 |
| 重复、不可验证、无许可证或只适用于旧机器的代码 | 拒绝迁移并记录理由 |

## 6. 完成定义

任何迁移只有同时具备以下证据才可标记 `ok`：

1. 来源仓与 source SHA；
2. 目标项目与目标模块；
3. 行为 contract 与回归测试；
4. 隐私、secret、许可证与运行数据检查；
5. 目标仓完整门禁；
6. Mac mini 固定 SHA 部署、健康检查与回滚记录。
