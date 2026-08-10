# AI4Research Mac mini deployment

This contract deploys a committed AI4Research tree from the MacBook to an
independent Mac mini root. It does not use or modify `/Users/sihaoli/Projects/Solar`,
GenesisPod, ThunderOMLX, or the existing `~/.solar` runtime.

## Layout

```text
~/Services/AI4Research/
  releases/<full-commit-sha>/
  current -> releases/<full-commit-sha>
  previous -> releases/<previous-sha>
  shared/harness/{run,state,logs,cache,sprints,intents,runs}/
  runtime-home/
  config/
  logs/
  evidence/deployments/
```

The release archive is addressed by a 40-character Git commit SHA and a
SHA-256 transport checksum. Runtime directories are outside the release tree.
Activation replaces `current` atomically, restarts the dedicated launchd
service, and requires `/healthz` to pass. A failed activation restores the
previous release when one exists.

## Deploy and verify

```bash
bash scripts/deploy-ai4research-mac-mini.sh
bash scripts/ai4research-mac-mini-status.sh
```

The deploy command runs the fast local gate unless `--no-local-gate` is given
explicitly. The service is bound only to `127.0.0.1:8875` on the Mac mini.

## MacBook access without a token

```bash
bash scripts/ai4research-tunnel.sh start
open http://127.0.0.1:18875/
```

The browser reaches the loopback-only service through the existing SSH key.
There is no application token or password to remember, and the service is not
published to the LAN.

Stop or inspect the tunnel with:

```bash
bash scripts/ai4research-tunnel.sh status
bash scripts/ai4research-tunnel.sh stop
```

## Rollback proof

```bash
bash scripts/ai4research-mac-mini-rollback-test.sh
```

This activates a deliberately invalid synthetic release, requires its health
check to fail, restores the previously healthy SHA, and writes a rollback
record under `evidence/deployments/`. It succeeds only when restored health is
observed.
