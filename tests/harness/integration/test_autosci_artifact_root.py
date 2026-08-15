from __future__ import annotations

from pathlib import Path

from .autosci_product_smoke_helpers import (
    assert_under,
    load_stdout_json,
    prepare_isolated_harness,
    repo_run_dir,
    run_autosci,
    unique_run_id,
    write_demo_paper,
)


def test_product_autosci_outputs_stay_under_unified_harness_dir(tmp_path: Path) -> None:
    harness_dir = prepare_isolated_harness(tmp_path)
    paper = write_demo_paper(harness_dir)
    run_id = unique_run_id("phase-c-root")

    # This isolated run verifies artifact placement, not the outer lifecycle
    # approval boundary; only the local paper-ingest node is selected.
    proc = run_autosci(
        harness_dir,
        f"$research phase-c root --paper {paper} --scheduler-run "
        f"--scheduler-timeout 20 --gate-mode autosci_native --run-id {run_id}",
    )
    summary = load_stdout_json(proc)

    assert_under(summary["evidence_path"], harness_dir)
    assert_under(summary["wiki_path"], harness_dir)
    assert_under(summary["scheduler_lifecycle_summary_path"], harness_dir)
    assert (harness_dir / "artifacts" / "autosci" / "runs" / run_id).is_dir()
    assert (harness_dir / "artifacts" / "scientific" / "workflow-runs" / f"{run_id}-scheduler").is_dir()
    assert not repo_run_dir(run_id).exists()
