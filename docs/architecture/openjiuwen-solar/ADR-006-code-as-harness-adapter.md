# ADR-006: Code-as-Harness 仅作为交付门禁适配层

## 状态

Accepted

## 背景

`harness/` 已经拥有 OpenJiuwen Solar 的 Requirement、TaskGraph、operator、gate、evidence 与 closure 语义。为了让 Codex、Claude 和 CI 对同一组项目原生门禁进行确定性调用，需要一个可移植的变更范围选择器和 Git 提交证明，但不能再创建第二套运行时事实源。

## 决策

- `harness/` 继续是唯一 canonical execution runtime 和产品证据事实源。
- `.agent-governance/profile.json` 只把变更路径映射到已有的 `scripts/test-local-fast.sh` 与 `scripts/test-local-full.sh`。
- `tools/agent-development-governance/` 是只读门禁调度器；它不拥有 TaskGraph、operator、closure 或运行时状态。
- 适配层不重复执行 Solar CI 已拥有的 secret scanner；本地凭据检查由原生 fast/full gate 执行，远端由 Solar CI 执行。
- 本地 attestation 只写入 Git metadata 的 `governance-attestation.json`，绑定 Profile、HEAD、changed paths 与文件字节，不进入 `harness/`，也不提交到仓库。
- `.githooks/pre-push` 对非平凡代码变更运行 full gate，并在证据仍新鲜时才允许推送。
- 独立 GitHub workflow 校验适配层并上传精确 SHA 的 attestation；原有 Solar CI 继续拥有产品测试与发布门禁权威。
- 只有 required CI 和分支保护实际配置完成后，才可将远端合并门标记为 `enforced`。

## 权威边界

| 责任 | 权威来源 |
| --- | --- |
| Requirement、TaskGraph、operator、产品 gate、evidence、closure | `harness/` |
| 本地快速与完整验证命令 | `scripts/test-local-fast.sh`、`scripts/test-local-full.sh` |
| 变更范围选择和提交证明 | `.agent-governance/profile.json` + portable verifier |
| 合并判定 | Solar CI + Governance attestation + GitHub branch protection |
| 部署与运行证据 | commit-addressed deployment record；不进入本适配层 |

## 失败关闭规则

1. required gate 未运行、失败、超时或输出不可解析时，不得标记完成。
2. commit 改变 HEAD 后必须重新执行 full gate 并重新 attestation。
3. Profile、HEAD、changed paths 或文件字节变化会使旧 attestation 失效。
4. 推送后必须核对远端 SHA，并等待 required CI；失败时继续修复，不得以 agent 自述替代证据。
5. 不允许用 skip、allowlist、baseline 降级或删除测试来换取绿色结果。

## 后果

- 新增的是交付控制面，不是第二个 Solar Harness。
- Codex 与 Claude 可以共享同一 Profile 和同一组可执行门禁。
- 上游仓库权限或分支保护缺失属于外部 `warn/error`，不能由本地 attestation 冒充完成。
