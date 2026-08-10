# ADR-005: 两个独立目标项目与一个特性来源仓

## 状态

Accepted by user direction on 2026-08-10

## 背景

后续开发同时涉及 Solar 平台能力和个人洞察报告产品。若把 AI4Research、GenesisPod 与 solar-harness 当成一个项目，会混淆主干、产品边界、部署状态和特性归属。

## 决策

- `AI4Research/openJiuwen-Solar` 是 Solar 唯一主仓和集成主干；
- `<user-fork>/GenesisPod` 是独立项目，不被定义为 AI4Research 的产品界面；
- `<user-fork>/solar-harness` 只作为特性来源仓，不成为新的目标主干；
- 第一阶段允许盘点和迁移已经推送、可固定 SHA 的特性；
- runtime/Harness/agent/research 基础能力默认进入 AI4Research；
- 大咖、Hugging Face、GitHub、YouTube 趋势洞察及报告工作流默认进入 GenesisPod；
- 2026-05-20 至 2026-07-20 的未完成特性属于第二阶段候选池，必须逐项选择、开发、测试和合入；
- MacBook 开发两个项目，Mac mini 用两套独立 release/runtime 运行两个项目。

## 后果

- 正向：主干、产品归属、运行状态和回滚边界清晰；
- 负向：共享能力需要 contract/adapter，而不能直接共享可变代码目录；
- 缓解：建立 machine-readable import manifest 和 destination routing 字段。

## 复审触发

只有用户明确改变项目归属，或两个项目形成经过版本化验证的公共包，才复审本决策。
