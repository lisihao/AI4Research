# ADR-003: MacBook 开发、Mac mini 固定 SHA 运行

## 状态

Proposed

## 背景

开发与长时间运行混在同一工作树会引入未提交代码、环境差异和无法回滚的部署。Solar 当前又依赖本地文件系统、SQLite、tmux 和用户级 daemon，因此应先用明确的机器职责隔离风险。

## 决策

- MacBook 是开发、Codex 控制、测试和部署发起端；
- Mac mini 是 clean runner，不进行手工源码开发；
- 部署以 commit SHA/release manifest 为单位；
- Mac mini 使用不可变 `releases/<sha>` 与原子 `current` 链接；
- AI4Research 与 GenesisPod 使用独立的 release roots、配置、状态、日志、端口和 launchd labels；
- 状态、secret、日志和 artifacts 位于 `~/.solar/`，与 release 分离；
- status/remote-control 只经 SSH 隧道或受控私网访问。

## 备选方案

| 方案 | 优点 | 缺点 |
|---|---|---|
| rsync 当前工作树 | 快 | 不可审计、不可复现、易带入脏文件 |
| Mac mini 直接开发 | 少一步部署 | 运行与开发相互污染 |
| 立即容器/Kubernetes | 隔离更强 | 对本地 macOS/tmux/Keychain 集成过重 |

## 后果

- 正向：可复现、可回滚、运行稳定；
- 负向：需要维护 bootstrap/deploy/monitor 脚本；
- 缓解：先实现最小 SSH + launchd 版本，再增加自动化。

## 复审触发

出现多台运行节点、容器化依赖明确，或 macOS 本地能力不再需要。
