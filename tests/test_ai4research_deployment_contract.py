from pathlib import Path


REPO = Path(__file__).resolve().parents[1]


def test_status_service_keeps_runtime_home_but_projects_codex_home() -> None:
    template = (
        REPO
        / "deploy/ai4research/com.ai4research.solar.status-server.plist.template"
    ).read_text(encoding="utf-8")
    remote = (REPO / "scripts/remote-ai4research-release.sh").read_text(
        encoding="utf-8"
    )

    assert "__ROOT__/runtime-home" in template
    assert "<key>CODEX_HOME</key>" in template
    assert "__USER_HOME__/.codex" in template
    assert 's|__USER_HOME__|$user_home|g' in remote


def test_macbook_tunnel_is_launchd_managed_and_self_healing() -> None:
    template = (
        REPO / "deploy/ai4research/com.ai4research.solar.tunnel.plist.template"
    ).read_text(encoding="utf-8")
    manager = (REPO / "scripts/ai4research-tunnel.sh").read_text(encoding="utf-8")

    assert "<key>KeepAlive</key>" in template
    assert "ServerAliveInterval=30" in template
    assert "ExitOnForwardFailure=yes" in template
    assert "launchctl bootstrap" in manager
    assert "launchctl enable" in manager
    assert "legacy_socket" in manager
