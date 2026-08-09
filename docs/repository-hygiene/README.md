# Repository hygiene policy

The maintained branch keeps source, tests, packaging inputs, and durable
documentation in the working tree. Generated run evidence, local orchestration
state, machine-specific helper scripts, and exported workbooks belong outside
Git.

## 2026-08-09 forward cleanup

The cleanup is forward-only: it removes 1,838 tracked paths (430,805,072 bytes
in the checkout) without rewriting repository history. Every removed path can
be recovered from baseline commit `4d60f1e03b40b3e1bb618afe7136ef1687f2d5a4`.

Inspect a removed tree without restoring it:

```bash
git ls-tree -r 4d60f1e03b40b3e1bb618afe7136ef1687f2d5a4 -- "harness/artifacts"
```

Restore a specific path into the worktree and index when intentionally needed:

```bash
git restore --source 4d60f1e03b40b3e1bb618afe7136ef1687f2d5a4 -- "harness/artifacts"
```

See `cleanup-manifest.json` for the exact object IDs, counts, and rationale.
A future history rewrite would require a separate owner-approved migration; it
is not part of this cleanup.

## Placement rules

- Keep reproducible fixtures and tests close to their owning source package.
- Write runtime output to ignored directories such as `harness/artifacts/`,
  `harness/tmp/`, or a caller-provided external artifact directory.
- Do not commit absolute user paths, local caches, generated spreadsheets, run
  logs, or task-specific orchestration state.
- Keep public maintenance evidence small, text-based, and reproducible from a
  documented command.
