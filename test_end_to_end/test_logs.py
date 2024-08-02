import os
import secrets
import subprocess
from pathlib import Path

from . import util
from .conftest import Server


def test_quiet(executable: str, server: Server, tmp_path: Path) -> None:
    trace_file = tmp_path / "trace.cst.gz"

    with util.open_java_trace() as f:
        trace_file.write_bytes(f.read())

    result = subprocess.run(
        util.cmd_upload_trace(
            executable,
            quiet=True,
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

    assert util.Result.from_subprocess(result) == util.Result.clean(
        code=0,
        stdout="",
        stderr="",
    )


def test_verbose(executable: str, server: Server, tmp_path: Path) -> None:
    trace_file = tmp_path / "trace.cst.gz"

    with util.open_java_trace() as f:
        trace_file.write_bytes(f.read())

    result = subprocess.run(
        util.cmd_upload_trace(
            executable,
            verbose=True,
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
    ).replace(regex=r"https://[^ \r\n]+", text="<url>") == util.Result.clean(
        code=0,
        stdout="",
        stderr="""
            DEBUG    HTTP request: POST <url>
            DEBUG    HTTP response: 200
            DEBUG    HTTP request: POST <url>
            DEBUG    HTTP response: 201
            DEBUG    HTTP request: POST <url>
            DEBUG    HTTP response: 200
            INFO     Trace <trace_id> uploaded
        """,
    )


def test_colors_always(executable: str, server: Server, tmp_path: Path) -> None:
    trace_file = tmp_path / "trace.cst.gz"

    with util.open_java_trace() as f:
        trace_file.write_bytes(f.read())

    result = subprocess.run(
        util.cmd_upload_trace(
            executable,
            color="always",
            api_base_url="https://localhost:1",
            project_id=str(server.project_id),
            trace_file=str(trace_file),
        ),
        env=dict(os.environ, CRYPTOSENSE_API_KEY=server.api_key),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    bold = "\x1b[1m"
    red = "\x1b[31m"
    reset = "\x1b[0;1m\x1b[0m"
    assert (
        util.Result.from_subprocess(result).replace(
            regex=r": [^\r\n]+", text=": <libcurl_error>"
        )
    ) == util.Result.clean(
        code=1,
        stdout="",
        stderr=f"""
            {bold}{red}ERROR    {reset}HTTP error (CURLE_COULDNT_CONNECT): <libcurl_error>
        """,
    )
