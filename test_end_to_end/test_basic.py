import subprocess

from . import util


def test_no_args(executable: str) -> None:
    result = subprocess.run(
        util.cmd(executable), stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )

    assert result.returncode == 124
    assert result.stdout.decode() == ""
    assert result.stderr.decode() == util.output_str(
        """
        cs-api: Missing command
        Usage: cs-api [COMMAND] …
        Try 'cs-api --help' for more information.
        """
    )
