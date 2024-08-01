import os
import secrets
import subprocess
from pathlib import Path

from . import util
from .conftest import Server


def test_upload_and_analyze_file_ok(
    executable: str, server: Server, tmp_path: Path
) -> None:
    trace_file = tmp_path / "trace.cst.gz"

    with util.open_java_trace() as f:
        trace_file.write_bytes(f.read())

    result = subprocess.run(
        util.cmd_upload_trace(
            executable,
            **util.good_connection_args(server),
            project_id=str(server.project_id),
            slot_name=server.slot_name,
            trace_file=str(trace_file),
            trace_name=f"trace-{secrets.token_hex(8)}",
            analyze=str(server.profile_id),
        ),
        env=dict(os.environ, CRYPTOSENSE_API_KEY=server.api_key),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    assert (
        util.Result.from_subprocess(result)
        .replace(regex=r"Trace \d+ uploaded", text="Trace <trace_id> uploaded")
        .replace(regex=r"ID \d+", text="ID <trace_id>")
        .replace(regex=r"Report for [a-zA-Z0-9:\-.]+", text="Report for <trace_name>")
    ) == util.Result.clean(
        code=0,
        stdout="""
            Trace <trace_id> uploaded
            Report 'Report for <trace_name>' of ID <trace_id> is being generated
        """,
        stderr="",
    )


def test_upload_and_analyze_file_failure(
    executable: str, server: Server, tmp_path: Path
) -> None:
    trace_file = tmp_path / "trace.cst.gz"
    trace_file.write_bytes(b"invalid-trace-data")

    result = subprocess.run(
        util.cmd_upload_trace(
            executable,
            **util.good_connection_args(server),
            project_id=str(server.project_id),
            slot_name=server.slot_name,
            trace_file=str(trace_file),
            trace_name=f"trace-{secrets.token_hex(8)}",
            analyze=str(server.profile_id),
        ),
        env=dict(os.environ, CRYPTOSENSE_API_KEY=server.api_key),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    assert (
        util.Result.from_subprocess(result).replace(
            regex=r"Trace \d+ uploaded", text="Trace <trace_id> uploaded"
        )
    ) == util.Result.clean(
        code=1,
        stdout="""
            Trace <trace_id> uploaded
            This trace is still being processed
        """,
        stderr="",
    )
