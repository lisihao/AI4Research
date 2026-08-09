from __future__ import annotations

import importlib.util
import socket
from pathlib import Path


STATUS_SERVER = Path(__file__).resolve().parents[1] / "lib" / "symphony" / "status-server.py"
SPEC = importlib.util.spec_from_file_location("solar_status_server_fast_bind", STATUS_SERVER)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def test_status_server_bind_does_not_reverse_resolve(monkeypatch) -> None:
    def fail_getfqdn(_host: str = "") -> str:
        raise AssertionError("numeric status-server bind must not call socket.getfqdn")

    monkeypatch.setattr(socket, "getfqdn", fail_getfqdn)
    server = MODULE.StatusThreadingHTTPServer(("127.0.0.1", 0), MODULE.StatusHandler)
    try:
        assert server.server_name == "127.0.0.1"
        assert server.server_port > 0
    finally:
        server.server_close()
