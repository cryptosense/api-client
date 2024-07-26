import inspect
import os
import re
import subprocess
from dataclasses import dataclass
from importlib.resources import files
from typing import IO, Any, Mapping, Sequence

from .conftest import Server


def open_java_trace() -> IO[bytes]:
    return files("test_end_to_end").joinpath("data/java_trace.cst.gz").open("rb")


def cmd(executable: str) -> Sequence[str]:
    """
    Return command-line arguments for running `cs-api` without a subcommand.
    """

    return [executable]


def good_connection_args(server: Server) -> Mapping[str, Any]:
    """
    Provide good arguments for the connection, regardless of the server.

    Don't use it if you are testing connection behavior.
    """

    args: dict[str, Any] = {"api_base_url": server.api_url}

    if server.ca_path is not None:
        args["ca_file"] = server.ca_path
        return args

    if not server.trusted_cert:
        args["no_check_certificate"] = True
        return args

    return args


def cmd_upload_trace(
    executable: str,
    color: str | None = None,
    quiet: bool = False,
    verbose: bool = False,
    api_base_url: str | None = None,
    api_key: str | None = None,
    no_check_certificate: bool = False,
    ca_file: str | None = None,
    project_id: str | None = None,
    slot_name: str | None = None,
    trace_name: str | None = None,
    trace_file: str | None = None,
    analyze: str | None = None,
) -> Sequence[str]:
    """
    Return command-line arguments for uploading a trace.

    This is a light wrapper around `cs-api upload-trace`. It's meant to be dumb.
    """

    cli = list(cmd(executable))
    cli.extend(["upload-trace"])

    if color is not None:
        cli.extend(["--color", color])

    if quiet:
        cli.extend(["--quiet"])

    if verbose:
        cli.extend(["--verbose"])

    if api_base_url is not None:
        cli.extend(["--api-base-url", api_base_url])

    if api_key is not None:
        cli.extend(["--api-key", api_key])

    if no_check_certificate:
        cli.extend(["--no-check-certificate"])

    if ca_file is not None:
        cli.extend(["--ca-file", ca_file])

    if project_id is not None:
        cli.extend(["--project-id", project_id])

    if slot_name is not None:
        cli.extend(["--slot-name", slot_name])

    if trace_name is not None:
        cli.extend(["--trace-name", trace_name])

    if trace_file is not None:
        cli.extend(["--trace-file", trace_file])

    if analyze:
        cli.extend(["--analyze", analyze])

    return cli


def output_str(s: str) -> str:
    clean_str = inspect.cleandoc(s)
    new_str = f"{clean_str}\n"

    if os.linesep != "\n":
        new_str = new_str.replace("\n", os.linesep)

    return new_str


@dataclass(frozen=True)
class Result:
    code: int
    stdout: str
    stderr: str

    @classmethod
    def from_subprocess(cls, result: subprocess.CompletedProcess[bytes]) -> "Result":
        return cls(
            code=result.returncode,
            stdout=result.stdout.decode(),
            stderr=result.stderr.decode(),
        )

    @classmethod
    def clean(cls, code: int, stdout: str, stderr: str) -> "Result":
        """
        Helper to create an "expected" `Result`.
        """

        return cls(
            code=code,
            stdout=(output_str(stdout) if stdout else stdout),
            stderr=(output_str(stderr) if stderr else stderr),
        )

    def replace(self, regex: str, text: str) -> "Result":
        """
        Create a new `Result` with transformed `stdout` and `stderr`.

        This is meant to replace dynamic parts of the output on a result from `subprocess`.
        """

        return Result(
            code=self.code,
            stdout=re.sub(regex, text, self.stdout),
            stderr=re.sub(regex, text, self.stderr),
        )
