#!/usr/bin/env python3
"""Synchronize maintained release metadata from the root VERSION file."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


JSON_TARGETS = {
    "package.json": [()],
    "desktop/package.json": [()],
    "desktop/package-lock.json": [(), ("packages", "")],
}
TAG_SURFACES = (
    "README.md",
    "INSTALL.md",
    "docs/FIRST-SESSION.md",
    "docs/RELEASE-CHECKLIST.md",
    "get-solar.sh",
    "install.ps1",
    "distribution/pipx/README.md",
    "distribution/pipx/opensolar_cli/cli.py",
    "distribution/pipx/tests/test_cli.py",
    "desktop/bootstrap-contract.test.js",
)
BARE_VERSION_SURFACES = (
    "README.md",
    "docs/FIRST-SESSION.md",
    "docs/RELEASE-CHECKLIST.md",
)
TAG_RE = re.compile(r"v\d+\.\d+\.\d+(?:-rc\.\d+)?")
SEMVER_RE = re.compile(r"(?<![A-Za-z0-9])\d+\.\d+\.\d+-rc\.\d+(?![A-Za-z0-9])")
PEP440_RE = re.compile(r"(?<![A-Za-z0-9])\d+\.\d+\.\d+rc\d+(?![A-Za-z0-9])")
VERSION_RE = re.compile(r"^(\d+\.\d+\.\d+)(?:-rc\.(\d+))?$")


def pep440(version: str) -> str:
    match = VERSION_RE.fullmatch(version)
    if not match:
        raise ValueError(f"unsupported VERSION format: {version!r}")
    base, release_candidate = match.groups()
    return base if release_candidate is None else f"{base}rc{release_candidate}"


def _set_nested_version(document: dict, keys: tuple[str, ...], version: str) -> None:
    target = document
    for key in keys:
        target = target[key]
    target["version"] = version


def _replace(path: Path, transform, *, write: bool) -> bool:
    original = path.read_text(encoding="utf-8")
    updated = transform(original)
    if updated == original:
        return False
    if write:
        path.write_text(updated, encoding="utf-8")
    return True


def synchronize(root: Path, *, write: bool) -> list[str]:
    version = (root / "VERSION").read_text(encoding="utf-8").strip()
    pip_version = pep440(version)
    tag = f"v{version}"
    changed: list[str] = []

    for relative, key_paths in JSON_TARGETS.items():
        path = root / relative
        document = json.loads(path.read_text(encoding="utf-8"))
        for keys in key_paths:
            _set_nested_version(document, keys, version)
        updated = json.dumps(document, ensure_ascii=False, indent=2) + "\n"
        if updated != path.read_text(encoding="utf-8"):
            changed.append(relative)
            if write:
                path.write_text(updated, encoding="utf-8")

    replacements = {
        "distribution/pipx/pyproject.toml": lambda text: re.sub(
            r'(?m)^version = "[^"]+"$', f'version = "{pip_version}"', text
        ),
        "distribution/pipx/opensolar_cli/__init__.py": lambda text: re.sub(
            r'(?m)^__version__ = "[^"]+"$', f'__version__ = "{pip_version}"', text
        ),
    }
    for relative, transform in replacements.items():
        if _replace(root / relative, transform, write=write):
            changed.append(relative)

    for relative in TAG_SURFACES:
        if _replace(root / relative, lambda text: TAG_RE.sub(tag, text), write=write):
            changed.append(relative)

    for relative in BARE_VERSION_SURFACES:
        def replace_bare(text: str) -> str:
            return PEP440_RE.sub(pip_version, SEMVER_RE.sub(version, text))

        if _replace(root / relative, replace_bare, write=write):
            changed.append(relative)

    return sorted(set(changed))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="report drift without writing")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()

    changed = synchronize(args.root.resolve(), write=not args.check)
    if args.check and changed:
        print("version metadata drift:", file=sys.stderr)
        for path in changed:
            print(f"  {path}", file=sys.stderr)
        return 1
    action = "checked" if args.check else "synchronized"
    print(f"version metadata {action}: {len(changed)} file(s) changed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
