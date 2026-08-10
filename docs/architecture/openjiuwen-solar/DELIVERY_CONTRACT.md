# Delivery Contract: OpenJiuwen Solar 主干采用计划

状态：Active for planning

日期：2026-08-06

## 1. 输入

- 目标仓：`https://github.com/Stellven/AI4Research.git`
- 目标分支：`openJiuwen-Solar`
- 当前同步基线 SHA：`5cccc0b495cad52b473ad751d7822cfdbb77665d`
- 第二目标仓：`<user-fork>/GenesisPod`（独立项目；真实 remote 仅存本机 Git 配置）
- 特性来源仓：`<user-fork>/solar-harness`（第一阶段已推送部分已释放；未完成部分逐项门禁）
- 设备边界：MacBook 开发与控制；Mac mini 独立运行 AI4Research 与 GenesisPod

## 2. 必须交付

1. 独立目录中的完整目标分支 clone。
2. 以真实代码、manifest、CI 和门禁结果为依据的现状分析。
3. PRD、目标架构、重大 ADR 与机器可读 task graph。
4. MacBook/Mac mini/GitHub/Codex 的职责与信任边界。
5. `solar-harness` 两阶段迁移协议：已推送部分可盘点，未完成部分保持逐项选择门禁。
6. AI4Research、GenesisPod 与 solar-harness 的项目角色、目标路由和两阶段迁移语境。

## 3. Guardrails

- `/Users/sihaoli/Projects/Solar` 是独立项目且完全不在本计划范围内；不得将其作为 AI4Research 的来源、旧仓或迁移对象，也不得读取或修改。
- 不执行历史重写、强推、删除分支或清除未跟踪文件。
- `solar-harness` 只允许固定 source SHA 后做只读 inventory；禁止整仓 merge、运行状态导入和机器配置导入。
- GenesisPod 与 AI4Research 不共享工作树、数据库、状态目录、release 链接或 launchd label。
- 2026-05-20 至 2026-07-20 的未完成特性在单项选择前保持 `hold`。
- 不提交、不推送本轮规划文件，除非用户另行授权。
- 不在测试中使用真实 HOME；安装测试必须使用 sandbox HOME。
- 不将 API key、token、cookie、个人配置或运行数据库写入仓库。
- 不把 Codex remote-control 或 Solar status server 绑定到公网接口。

## 4. 质量门禁

| Gate | 命令/方法 | 通过条件 |
|---|---|---|
| Git baseline | `git status -sb`; `git rev-parse HEAD` | 分支/SHA 正确，无非规划外改动 |
| Object integrity | `git fsck --full` | 无损坏对象 |
| Architecture docs | JSON parse + link/path check | PRD、contract、ADRs、task graph 完整 |
| Release coherence | `bash scripts/check-release-coherence.sh` | exit 0 |
| Privacy | `bash scripts/check-privacy.sh` | exit 0，或明确列出遗留失败 |
| Core imports | `bash scripts/check-core-imports.sh` | 安装锁定依赖后 exit 0 |
| Harness fast gate | CI 对应 Python/shell smoke | exit 0 |
| Deployment | fixed-SHA deploy + health + rollback drill | 三项证据齐全 |

## 5. 状态定义

- `ok`：已执行并有新鲜证据；
- `pending`：已规划、依赖可满足但尚未执行；
- `warn`：有明确缺口或非阻断失败；
- `error`：阻断当前节点；
- `hold`：按用户指令不得开始，不视为失败。

## 6. 停止条件

只有以下情况可停止自动推进：

- 需要用户授权的 destructive/history rewrite；
- `solar-harness` 目标分支/source SHA 无法固定，或迁移项来源不在已推送范围；
- 第二阶段候选特性尚未经过单项选择，却要求批量导入；
- 缺少 GitHub/Mac mini 凭据且无法做只读验证；
- 安全边界要求暴露公网或处理未知 secret；
- 目标分支发生不可自动调和的上游历史变化。

## 7. 变更策略

- 一个 task graph 节点对应一个可审查变更；
- 功能分支使用 `codex/<topic>`；
- 每个提交只覆盖一个工作流；
- 先添加 contract/test，再修改 runtime；
- 部署按 commit SHA，不按“某台机器当前目录”；
- 未通过证据 gate 的结果不得标为完成。
