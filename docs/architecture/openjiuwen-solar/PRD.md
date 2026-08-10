# PRD: OpenJiuwen Solar 主干与双机开发环境

状态：Active

日期：2026-08-06

目标主干：`Stellven/AI4Research#openJiuwen-Solar`

开发语境：[DEVELOPMENT_CONTEXT.md](./DEVELOPMENT_CONTEXT.md)

## 1. 背景

Solar 后续开发以 `Stellven/AI4Research` 的 `openJiuwen-Solar` 分支为唯一主干。`<user-fork>/GenesisPod` 是第二个独立目标项目，用于洞察分析与报告产品；它不是 AI4Research 的 UI 或子项目。`<user-fork>/solar-harness` 只作为特性来源仓，不作为目标主干。

用户已于 2026-08-10 释放 `solar-harness` 已推送部分的盘点与迁移门禁。未完成特性仍按 2026-05-20 至 2026-07-20 候选池逐项选择、开发、测试和合入，不做整仓合并。

开发环境采用双机分工：

- MacBook：代码、评审、Codex 控制与部署发起端；
- Mac mini：AI4Research 与 GenesisPod 两套独立固定提交的运行、任务执行、状态与证据生成端；
- GitHub：代码、PR、发布物和审计记录的协作事实源；
- 运行时状态：保留在 Mac mini 的 `~/.solar/`，不反向提交到 Git。

## 2. 当前基线

| 项目 | 当前事实 | 影响 |
|---|---|---|
| 主干分支 | `openJiuwen-Solar`，同步基线 `7c7e769a03a1ea80b3f80551352b3354e400cdbd` | 后续变更以此为基线 |
| 与 `main` 关系 | `main` 0 个独有提交，目标分支领先 425 个提交 | `openJiuwen-Solar` 已是事实产品主线 |
| 主运行时 | `harness/` Bash/Python | 新功能优先沿此路径演进 |
| 可选运行时 | `core/` Bun/TypeScript | 只能通过已定义契约演进，不另建事实源 |
| 发布版本 | `VERSION=1.0.0-rc.9`；root package 为 `3.0.0` | 需要统一版本事实源 |
| 仓库规模 | 5,778 个 tracked files；工作树约 1.2 GB；Git pack 约 784 MiB | 克隆、CI、审查成本偏高 |
| 大文件 | `Feature list stuff/` 约 370 MB | 应迁往 Release/LFS/归档仓 |
| tracked ignored | 677 个，其中 `harness/artifacts/` 667 个 | 运行证据与源码边界需修复 |
| 本机工具链 | Bun 1.3.8；Python 3.9.6 | Python 未达到 3.11+ 要求 |

## 3. 用户与核心场景

### 3.1 开发者

在 MacBook 上创建短生命周期功能分支，使用 Codex 修改与验证代码，通过 PR 合入 `openJiuwen-Solar`。

### 3.2 运行维护者

从 MacBook 将已通过门禁的 commit SHA 部署到 Mac mini，观察健康、任务、日志、证据与回滚状态，不在运行机直接改源码。

### 3.3 Harness 特性迁移者

对 `<user-fork>/solar-harness` 已推送部分做只读盘点，将每项特性映射到 AI4Research 或 GenesisPod 的目标架构与验收契约，再逐项迁移。未完成候选特性必须经过第二阶段单项选择门禁。

## 4. 目标

1. 建立 `openJiuwen-Solar` 作为唯一开发主干和发布候选来源。
2. 保持 `harness/` 为当前 canonical execution runtime，明确 `core/` 的兼容与实验边界。
3. 把产品源码、运行状态、测试证据、演示资产和私密配置分开治理。
4. 建立 MacBook 开发、GitHub 审核、Mac mini 运行的 commit-addressed 部署链路。
5. 建立 Codex 的本地开发、远程辅助控制和 Mac mini 可观测性边界。
6. 为未来 `solar-harness` 特性迁移提供可重复、可回滚的导入协议。
7. 保持 GenesisPod 与 AI4Research 的源码、状态、部署和产品语义相互独立。

## 5. 非目标

- 不把 `<user-fork>/solar-harness` 作为第三条主干或执行整仓 merge。
- 不把 GenesisPod 变成 AI4Research 的 UI、子目录、子模块或共享运行时。
- 不对当前 425 个提交做历史重写。
- 不把 Solar 改造成多租户云控制平面。
- 不同时重写 Bash/Python Harness 与 TypeScript Core。
- 不将 Codex `remote-control` 直接暴露到公网。
- 不在 Mac mini 上建立长期手工开发分支。

## 6. 功能需求

### FR-1 仓库治理

- `openJiuwen-Solar` 是受保护的集成分支；日常修改通过 `codex/<topic>` 分支和 PR。
- 当用户 fork 就绪后，推荐 `origin=<user-fork>/AI4Research`、`upstream=Stellven/AI4Research`；真实 URL 只保留在本机 Git 配置。
- 每个发布物必须记录 commit SHA、版本、构建时间和门禁摘要。
- 源码、fixtures 与小型可复现证据可跟踪；运行目录、缓存、模型输出与临时报告不得跟踪。

### FR-2 架构边界

- `harness/` 拥有 Requirement IR、TaskGraph、scheduler、operator、gate、evidence、closure 的当前运行语义。
- `core/` 只通过版本化 schema/API 读取或驱动 Harness，不创建并行的权威状态。
- `desktop/`、dashboard 与 CLI 是 presentation/adaptor，不直接写内部状态文件。
- AutoSci 和未来能力以 plugin/capsule/skill 边界进入，不侵入调度核心。

### FR-3 MacBook 开发基线

- Python 3.11+、Bun、Git、jq、tmux、Codex CLI 版本固定并可诊断。
- 使用 repo-local virtual environment / dependency lock；不依赖系统 Python 3.9。
- 支持快速门禁、完整门禁和隐私/secret 门禁。

### FR-4 Mac mini 运行基线

- 运行目录使用 clean clone 或不可变 release bundle。
- 配置、secret、数据库、日志、artifacts 与源码分离。
- launchd 管理 status server、harness worker 和监控；进程可启动、停止、重启、回滚。
- 状态服务默认仅监听 loopback，通过 SSH tunnel 或私有网络访问。

### FR-5 部署与回滚

- 只部署已通过门禁的 SHA，不使用未提交目录同步作为发布手段。
- 部署采用 `releases/<sha>` + `current` 原子切换；保留上一版本。
- 失败时自动切回上一 SHA，运行数据不删除。

### FR-6 Codex 控制与监控

- MacBook Codex 是开发控制端，权限限定到目标 workspace。
- Mac mini Codex remote-control 仅作为实验性辅助通道，经 SSH 隧道和 token 使用。
- 稳定部署主通道仍为 Git/SSH/签名脚本；监控读取 health、task state、event/evidence ledger 和进程状态。

### FR-7 Harness 特性迁移

- 第一阶段仅盘点已经推送且可固定 source SHA 的特性。
- 每项特性按“已存在、直接移植、需适配、运行时数据、应丢弃”分类。
- runtime、Harness、agent、research infrastructure 默认进入 AI4Research。
- 大咖、Hugging Face、GitHub、YouTube 趋势洞察与报告工作流默认进入 GenesisPod。
- 禁止整目录覆盖；每项特性独立分支、测试、PR 和回滚说明。
- 第二阶段把 2026-05-20 至 2026-07-20 未完成工作作为候选池，逐项选择后才允许开发。

### FR-8 GenesisPod 独立开发与部署

- 使用 `<user-fork>/GenesisPod` fork 的独立工作区、分支、测试与 PR。
- 在 Mac mini 使用独立的 releases、current、config、secret、state、logs、launchd label 和端口。
- 洞察模块迁移必须适配 GenesisPod 自己的领域模型、API、存储与页面，不复制 AI4Research runtime。

## 7. 非功能需求

- 安全：secret 不进入 Git；远程控制不公网暴露；高权限动作需 allowlist/human gate。
- 可审计：部署、路由、gate、evidence 和回滚都关联 SHA 与事件记录。
- 可恢复：Mac mini 运行失败不污染 MacBook 工作树；回滚不破坏数据。
- 可移植：macOS 为第一优先级，Linux/WSL2 保持已有兼容边界。
- 性能：完成仓库清理后，普通开发 clone 不再携带演示视频与历史运行 artifacts。
- 简单性：在明确需要多机调度之前保持模块化单体，不引入微服务或分布式共识。

## 8. 验收标准

| ID | 验收条件 | 证据 |
|---|---|---|
| AC-01 | 目标仓干净跟踪 `origin/openJiuwen-Solar` | `git status -sb`、`git rev-parse HEAD` |
| AC-02 | 架构、PRD、契约、ADR 与 task graph 存在且互相引用 | `docs/architecture/openjiuwen-solar/` |
| AC-03 | MacBook Python 3.11+ 且快速门禁全通过 | bootstrap/doctor 报告 |
| AC-04 | tracked runtime artifacts 降为明确 allowlist | hygiene 报告、`git ls-files -ci` |
| AC-05 | 唯一发行版本事实源及一致性检查通过 | release-coherence 输出 |
| AC-06 | Mac mini 能部署固定 SHA、健康检查并回滚 | deployment evidence bundle |
| AC-07 | MacBook 可安全读取 Mac mini 监控面 | tunnel/health/monitor 证据 |
| AC-08 | 已推送与未完成 Harness 特性使用不同门禁 | task graph phase release 记录 |
| AC-09 | 每项 Harness 特性有来源 SHA、目标路由、contract、测试和回滚，不做盲目全量 merge | import manifest + PR evidence |
| AC-10 | GenesisPod 与 AI4Research 使用独立仓库和 Mac mini 运行目录 | repository/deployment inventory |

## 9. 假设与复审触发器

当前按个人或小团队、本地优先、单运行节点设计。出现以下任一条件时复审架构：

- 同时有 3 个以上长期运行节点；
- 需要多租户隔离或公网服务；
- Harness 与 Core 需要独立扩缩容；
- Mac mini 单机状态存储成为可靠性瓶颈；
- 团队规模超过 10 人并出现明确领域边界。
