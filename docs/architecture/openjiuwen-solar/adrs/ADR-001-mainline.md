# ADR-001: 采用 openJiuwen-Solar 作为产品主干

## 状态

Accepted by user direction

## 背景

`Stellven/AI4Research` 的 `openJiuwen-Solar` 已包含产品化 installer、Harness、AutoSci、Desktop、CI 和发行门禁，并比该仓库自己的 `main` 领先 425 个提交。`/Users/sihaoli/Projects/Solar` 是另一个独立项目，与本 ADR 没有源码、历史或迁移关系。

## 决策

- 后续产品开发以 `openJiuwen-Solar` 为集成主干；
- 日常工作在 `codex/<topic>` 分支完成，经 PR 合入；
- `/Users/sihaoli/Projects/Solar` 完全不在 AI4Research 的主干、来源与迁移边界内；
- 用户 fork 就绪后采用 `upstream=Stellven`、`origin=<user-fork>` 的远端模型；真实 URL 仅存本机配置。

## 备选方案

| 方案 | 优点 | 缺点 |
|---|---|---|
| 继续 `main` | 历史简单 | 丢失 425 个产品提交，重新整合成本高 |
| 将独立的 `/Users/sihaoli/Projects/Solar` 纳入本项目 | N/A | 项目边界错误，不予考虑 |
| 新建第三条主干 | 可自由重构 | 再次制造同步和发布歧义 |

## 后果

- 正向：单一产品基线、CI 与发布路径清晰；
- 负向：需要治理该分支已有的体积、artifacts 和版本债务；
- 缓解：P1 先做 forward cleanup，历史重写另行授权。

## 复审触发

上游正式将另一分支设为受保护发布主干，且提供可验证迁移路径。
