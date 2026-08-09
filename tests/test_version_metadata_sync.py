from __future__ import annotations

import importlib.util
import json
import shutil
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / "scripts" / "sync-version-metadata.py"
SPEC = importlib.util.spec_from_file_location("sync_version_metadata", SCRIPT)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def test_pep440_conversion() -> None:
    assert MODULE.pep440("1.2.3-rc.4") == "1.2.3rc4"
    assert MODULE.pep440("1.2.3") == "1.2.3"


def test_synchronize_updates_every_declared_surface(tmp_path: Path) -> None:
    targets = {"VERSION", *MODULE.JSON_TARGETS, *MODULE.TAG_SURFACES}
    targets.update(
        {
            "distribution/pipx/pyproject.toml",
            "distribution/pipx/opensolar_cli/__init__.py",
        }
    )
    for relative in targets:
        source = REPO / relative
        target = tmp_path / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)

    (tmp_path / "VERSION").write_text("2.3.4-rc.5\n", encoding="utf-8")
    changed = MODULE.synchronize(tmp_path, write=True)
    assert changed
    assert MODULE.synchronize(tmp_path, write=False) == []

    assert json.loads((tmp_path / "package.json").read_text())["version"] == "2.3.4-rc.5"
    lock = json.loads((tmp_path / "desktop/package-lock.json").read_text())
    assert lock["version"] == lock["packages"][""]["version"] == "2.3.4-rc.5"
    assert 'version = "2.3.4rc5"' in (
        tmp_path / "distribution/pipx/pyproject.toml"
    ).read_text()
    assert "v2.3.4-rc.5" in (tmp_path / "get-solar.sh").read_text()
