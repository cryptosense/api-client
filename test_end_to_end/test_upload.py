import os
import secrets
import subprocess
from pathlib import Path

from . import util
from .conftest import Server


def test_upload_file(executable: str, server: Server, tmp_path: Path) -> None:
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
        code=0,
        stdout="",
        stderr="""
            INFO     Trace <trace_id> uploaded
        """,
    )


def test_upload_file_from_directory(
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
            trace_file=str(tmp_path),
            trace_name=f"trace-{secrets.token_hex(8)}",
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
        code=0,
        stdout="",
        stderr="""
            INFO     Found trace file: trace.cst.gz
            INFO     Trace <trace_id> uploaded
        """,
    )


def test_upload_file_with_name(executable: str, server: Server, tmp_path: Path) -> None:
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
        code=0,
        stdout="",
        stderr="""
            INFO     Trace <trace_id> uploaded
        """,
    )


def test_upload_file_with_existing_name(
    executable: str, server: Server, tmp_path: Path
) -> None:
    trace_file = tmp_path / "trace.cst.gz"

    with util.open_java_trace() as f:
        trace_file.write_bytes(f.read())

    trace_name = f"trace-{secrets.token_hex(8)}"

    result = subprocess.run(
        util.cmd_upload_trace(
            executable,
            **util.good_connection_args(server),
            project_id=str(server.project_id),
            slot_name=server.slot_name,
            trace_file=str(trace_file),
            trace_name=trace_name,
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
        code=0,
        stdout="",
        stderr="""
            INFO     Trace <trace_id> uploaded
        """,
    )

    result = subprocess.run(
        util.cmd_upload_trace(
            executable,
            **util.good_connection_args(server),
            project_id=str(server.project_id),
            slot_name=server.slot_name,
            trace_file=str(trace_file),
            trace_name=trace_name,
        ),
        env=dict(os.environ, CRYPTOSENSE_API_KEY=server.api_key),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    assert (util.Result.from_subprocess(result)) == util.Result.clean(
        code=1,
        stdout="",
        stderr="""
            ERROR    A trace with the same name already exists
        """,
    )
