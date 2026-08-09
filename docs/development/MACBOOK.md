# MacBook development workstation

This repository treats the MacBook as the development and validation machine.
The Mac mini deployment/monitoring plane is a separate phase and is not
configured by these scripts.

## Bootstrap

Install the required system tools once:

```bash
brew install node@22 python@3.12 shellcheck gitleaks
```

Then create the locked Python environment, install root Bun dependencies, and
enable the repository-local pre-push hook:

```bash
bash scripts/bootstrap-macbook.sh
```

Use `--full` to also install the React dashboard and Electron desktop
dependencies:

```bash
bash scripts/bootstrap-macbook.sh --full
```

The scripts prepend Homebrew's keg-only Node 22 path for repository commands;
they do not modify `~/.zshrc` or replace another globally linked Node version.

## Gates

```bash
bash scripts/test-local-fast.sh  # required by the pre-push hook
bash scripts/test-local-full.sh  # dashboard and desktop validation too
```

The fast gate checks the workstation, privacy and secret scans, release/version
coherence, TypeScript import resolution, harness plumbing, Python compilation,
and the primary graph/dispatch CI smoke tests.

## Codex

`scripts/check-macbook-toolchain.sh` verifies the locally authenticated Codex
CLI is present and meets the minimum version in `config/dev-toolchain.json`.
Run a terminal-aware diagnostic separately when changing Codex configuration:

```bash
TERM=xterm-256color codex doctor --json
```

Do not store Codex credentials, Mac mini credentials, host addresses, or tokens
in this repository. Remote deployment and Mac mini monitoring will be added
only after the deployment contract and secret-storage boundary are approved.
