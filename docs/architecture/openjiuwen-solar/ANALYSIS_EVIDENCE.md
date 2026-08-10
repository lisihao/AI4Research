# Analysis and Verification Evidence

日期：2026-08-06

工作区：`/Users/sihaoli/Projects/AI4Research`

## 1. 初始 Git 基线（2026-08-06）

| 检查 | 结果 | 状态 |
|---|---|---|
| Remote | `https://github.com/Stellven/AI4Research.git` | ok |
| Branch | `openJiuwen-Solar` tracking `origin/openJiuwen-Solar` | ok |
| HEAD | `4d60f1e03b40b3e1bb618afe7136ef1687f2d5a4` | ok |
| Relation to main | `main` 独有 0；目标分支独有 425 | ok |
| Tracked files | 5,778 | warn |
| Worktree size | about 1.2 GB | warn |
| Git pack | about 784 MiB | warn |

## 2. 代码表面

| 区域 | Tracked files | 判断 |
|---|---:|---|
| `harness/` | 3,513 | 当前 canonical execution runtime |
| `docs/` | 947 | 文档与历史/测试证据较多，需要分层 |
| `Feature list stuff/` | 256+ | 约 370 MB，主要是源材料和大型媒体 |
| `core/` | 234 | 可选 Bun/TypeScript 演进线 |
| `skills/` | 196 | 通用能力资产 |
| `agents/` | 135 | Agent/persona 资产 |

## 3. 门禁结果

| Gate | 命令 | 结果 | 状态 |
|---|---|---|---|
| Release coherence | `bash scripts/check-release-coherence.sh` | PASS | ok |
| Privacy scan | `bash scripts/check-privacy.sh` | 9 处历史 `<owner>/Solar` 标识触发失败 | warn |
| Core import gate | `bash scripts/check-core-imports.sh` | 缺少 repo-local TypeScript 依赖 | warn |
| Python baseline | `python3 --version` | 3.9.6，低于要求的 3.11+ | warn |
| Bun baseline | `bun --version` | 1.3.8 | ok |
| Shell/JQ/tmux | local version probes | 已安装 | ok |

Privacy scan 的当前失败项位于 `Feature list stuff/Solar_Harness_All_Sources_2026-07-16/` 的历史引用。它们未被当作 secret 误报后直接删除；P1 应先决定公开身份与来源引用策略，再修改 scanner allowlist 或对应材料。

Core import gate 在 `bun install --frozen-lockfile` 之前不能证明通过。本轮没有为了架构分析而安装依赖或修改 lockfile。

## 4. 仓库卫生证据

- `git ls-files -ci --exclude-standard` 返回 677 个 tracked-but-ignored 条目；
- 其中 667 个位于 `harness/artifacts/`；
- `Feature list stuff/` 约 370 MB，包含多个演示视频、归档、文档与工作簿；
- `.gitattributes` 当前没有 Git LFS 规则；
- `.gitignore` 已表达“运行 artifacts 不入 Git”的目标，但历史 tracked files 尚未解除跟踪。

因此 P1 应先做路径/用途分类和 forward cleanup，再单独决定是否进行需要授权的历史重写。

## 5. 测试与 CI 表面

- GitHub Actions workflows: 5；
- repository-level tests: about 33；
- Harness tests: about 776；
- Desktop tests: about 10；
- `solar-ci.yml` 已监听 `openJiuwen-Solar`；
- Desktop 和部分安装 workflow 仍主要监听 `main` / `pkg/migration`，需要在 P1/P2 统一 branch policy。

## 6. Codex 远程能力

本机 `codex-cli 0.136.0` 提供：

- `codex remote-control start`；
- `codex remote-control stop`；
- `codex --remote <ws://...|wss://...|unix://...>`；
- bearer token environment option。

CLI 明确将 remote-control 标为 experimental，因此目标架构只将其作为 SSH tunnel 下的辅助通道，并保留 Git/SSH 部署与 Solar status/doctor 作为稳定回退。

## 7. 本轮边界证明

- 截至 2026-08-06 未添加、未 fetch、未 clone `<user-fork>/solar-harness`；该历史边界已被 2026-08-10 的第一阶段 source-inventory 释放取代；
- 当前目标仓唯一 remote 为 `Stellven/AI4Research`；
- `/Users/sihaoli/Projects/Solar` 与 AI4Research 是独立项目；本轮未对其做任何修改，后续也不得默认建立项目关系；
- 未提交、未推送任何变更；
- 本轮新增内容仅位于 `docs/architecture/openjiuwen-solar/`。

## 8. P1/P2 执行证据（2026-08-09）

| 节点 | 结果 | 状态 |
|---|---|---|
| P1 前向清理 | 移除 1,838 个 tracked paths / 430,805,072 bytes；可从 `4d60f1e0` 恢复 | ok |
| P1 隐私 | `check-privacy` + self-test PASS，Gitleaks tracked-tree no leaks | ok |
| P1 版本 | `VERSION=1.0.0-rc.9`；根包/桌面/pipx/公开文档一致 | ok |
| P1 提交 | `030e8b436`（从 `d0cc750b` 重放到最新主干） | ok |
| P2 工具链 | Python 3.12.13，Node 22.23.2，Bun 1.3.8，Codex 0.147.0 | ok |
| P2 提交 | `751f418d1`（从 `a031d03e` 重放到最新主干） | ok |
| Codex doctor | `overallStatus=ok`，auth/config/network/git/state/terminal 均可用 | ok |
| fast gate | 185 pytest，release/core/harness/privacy/secret 门禁全部通过 | ok |
| full gate | `PASS=9 FAIL=0 SKIP=2`；dashboard functional `9/9` | ok |
| macOS 启动修复 | status server bind 由约 35s 降至 1s；回归测试 PASS | ok |
| 保留边界 | 已推送部分允许只读盘点；未完成部分保持逐项选择门禁 | ok |

两个 full-gate SKIP 是当前非图形 macOS 会话无 display/xvfb，以及无 Windows
PowerShell；与此并行的 headless dashboard render、真实 backend contract 和 functional
E2E 均已通过。React 与 Electron 的 `npm audit` 分别仍报告 4 个 high，以及
4 high + 1 critical 的锁定依赖告警；本轮不运行可能破坏锁文件的自动修复。

## 9. 主干重同步与开发语境（2026-08-10）

| 检查 | 结果 | 状态 |
|---|---|---|
| GitHub 主干 | `origin/openJiuwen-Solar=7c7e769a03a1ea80b3f80551352b3354e400cdbd` | ok |
| 上游变化 | 相对旧开发分支新增 148 个提交 | warn |
| 安全快照 | 9 个规划文件 SHA-256 + `stash@{0}`；旧分支保留 | ok |
| 同步分支 | `codex/openjiuwen-bootstrap-sync-20260810` | ok |
| 本地重放 | `030e8b436`、`751f418d1` | ok |
| 项目组合 | AI4Research 与 GenesisPod 为两个独立目标项目；solar-harness 为特性来源 | ok |
| 第一阶段 | 已推送特性允许固定 SHA 后逐项盘点和迁移 | ok |
| 第二阶段 | 2026-05-20 至 2026-07-20 未完成特性逐项选择、开发、测试、合入 | ok |

冲突解决保留了最新上游 QA CSV；继续删除可重建的 `.inspect.ndjson` 和运行 artifacts；上游已移入 `tests/quarantine` 的隔离脚本予以保留。所有处理均在新同步分支完成，原开发分支未改写。

## 10. 最新主干验证闭环（2026-08-10）

| 检查 | 结果 | 状态 |
|---|---|---|
| Fast gate | `188 passed`；privacy、Gitleaks、release、core import、installer/harness plumbing 全部通过 | ok |
| Full gate | `PASS=9 FAIL=0 SKIP=2`；`AI4Research full local gate: PASS` | ok |
| Dashboard | headless render PASS；真实 backend functional E2E `9/9 passed` | ok |
| Desktop 平台项 | 当前会话无 display/xvfb，两个 Electron 可视项未验证 | pending |
| Windows 平台项 | 当前机器无 `powershell.exe`，Windows lint/Pester 未验证 | pending |
| ShellCheck | installer shell warning 级别检查通过 | ok |
| Secret/privacy | 约 197.92 MB tracked tree 无泄漏；个人 fork 名未写入公开文档 | ok |

重同步还暴露并修复了三类主干漂移：测试统一迁到 `tests/harness/` 后的旧路径引用；
task graph 规格与 runtime sidecar 分离后的过期状态断言；连续 desktop gate 未等待前一个
status-server 完成退出所产生的健康检查竞态。修复后由同一全量命令重新验证，不使用失败项跳过。

## 11. Mac mini 固定 SHA 部署与回滚（2026-08-10）

| 检查 | 结果 | 状态 |
|---|---|---|
| 独立根目录 | `~/Services/AI4Research`，未使用既有 `~/.solar` 或其他项目目录 | ok |
| Release contract | 完整 commit SHA + archive SHA-256 + `.solar-release.json` | ok |
| 原子激活 | `current -> releases/<sha>`，切换后 `readlink` 强制复核 | ok |
| launchd | `com.ai4research.solar.status-server`，`gui/501` | ok |
| 网络边界 | Mac mini 仅 `127.0.0.1:8875`；MacBook 经 SSH 转发到 `127.0.0.1:18875` | ok |
| 免 token 访问 | tunnel、dashboard 与 `/healthz` 可从 MacBook 访问 | ok |
| 负向回滚 | 无效 synthetic release 健康失败；恢复原 SHA 后 launchd/health 均为 ok | ok |
| 运行证据 | `~/Services/AI4Research/evidence/deployments/*.json` | ok |

首次负向演练发现两个真实的 macOS 语义问题：launchd `bootout`/`bootstrap` 需要等待与重试；
BSD `mv` 默认会跟随指向目录的目标符号链接。实现已增加 job 消失确认、bootstrap 重试、
`mv -h` 和切换后的 `readlink` 校验。失败演练产生的 4 个临时链接已按精确路径清理，
未删除源码、发布版本或运行数据；修复后的负向演练产生 `rollback_proven` 证据。
