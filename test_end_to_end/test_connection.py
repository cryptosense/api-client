import os
import secrets
import subprocess
import sys
from pathlib import Path

import pytest

from . import util
from .conftest import Server


def test_connection_error(executable: str, server: Server, tmp_path: Path) -> None:
    trace_file = tmp_path / "trace.cst.gz"

    with util.open_java_trace() as f:
        trace_file.write_bytes(f.read())

    result = subprocess.run(
        util.cmd_upload_trace(
            executable,
            api_base_url="https://localhost:1",
            project_id=str(server.project_id),
            slot_name=server.slot_name,
            trace_file=str(trace_file),
            trace_name=f"trace-{secrets.token_hex(8)}",
        ),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    assert (
        util.Result.from_subprocess(result).replace(
            regex=r": [^\r\n]+", text=": <libcurl_error>"
        )
    ) == util.Result.clean(
        code=1,
        stdout="",
        stderr="""
            ERROR    HTTP error (CURLE_COULDNT_CONNECT): <libcurl_error>
        """,
    )


@pytest.mark.skipif(sys.platform == "win32", reason="We need explicit CAs on Windows")
def test_default_ca(executable: str, server: Server, tmp_path: Path) -> None:
    if not server.trusted_cert:
        pytest.skip("Server without a certificate trusted by default CAs")

    trace_file = tmp_path / "trace.cst.gz"

    with util.open_java_trace() as f:
        trace_file.write_bytes(f.read())

    result = subprocess.run(
        util.cmd_upload_trace(
            executable,
            api_base_url=server.api_url,
            project_id=str(server.project_id),
            slot_name=server.slot_name,
            trace_file=str(trace_file),
            trace_name=f"trace-{secrets.token_hex(8)}",
        ),
        env=dict(os.environ, CRYPTOSENSE_API_KEY=server.api_key),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    assert util.Result.from_subprocess(result).replace(
        regex=r"Trace \d+ uploaded", text="Trace <trace_id> uploaded"
    ) == util.Result.clean(
        code=0,
        stdout="",
        stderr="""
            INFO     Trace <trace_id> uploaded
        """,
    )


def test_custom_ca(executable: str, server: Server, tmp_path: Path) -> None:
    if server.ca_path is None:
        pytest.skip("Server without a custom CA")

    trace_file = tmp_path / "trace.cst.gz"

    with util.open_java_trace() as f:
        trace_file.write_bytes(f.read())

    result = subprocess.run(
        util.cmd_upload_trace(
            executable,
            api_base_url=server.api_url,
            project_id=str(server.project_id),
            slot_name=server.slot_name,
            trace_file=str(trace_file),
            trace_name=f"trace-{secrets.token_hex(8)}",
            ca_file=server.ca_path,
        ),
        env=dict(os.environ, CRYPTOSENSE_API_KEY=server.api_key),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    assert util.Result.from_subprocess(result).replace(
        regex=r"Trace \d+ uploaded", text="Trace <trace_id> uploaded"
    ) == util.Result.clean(
        code=0,
        stdout="",
        stderr="""
            INFO     Trace <trace_id> uploaded
        """,
    )


def test_default_url(executable: str, server: Server, tmp_path: Path) -> None:
    if not server.is_default_url:
        pytest.skip("Server is not the default URL of the client (our SaaS version)")

    trace_file = tmp_path / "trace.cst.gz"

    with util.open_java_trace() as f:
        trace_file.write_bytes(f.read())

    result = subprocess.run(
        util.cmd_upload_trace(
            executable,
            project_id=str(server.project_id),
            slot_name=server.slot_name,
            trace_file=str(trace_file),
            trace_name=f"trace-{secrets.token_hex(8)}",
            ca_file=server.ca_path,
        ),
        env=dict(os.environ, CRYPTOSENSE_API_KEY=server.api_key),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    assert util.Result.from_subprocess(result).replace(
        regex=r"Trace \d+ uploaded", text="Trace <trace_id> uploaded"
    ) == util.Result.clean(
        code=0,
        stdout="",
        stderr="""
            INFO     Trace <trace_id> uploaded
        """,
    )
