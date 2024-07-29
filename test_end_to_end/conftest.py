import functools
import os
from dataclasses import dataclass
from typing import Any, Mapping

import pytest
import tomllib


@dataclass(frozen=True)
class Server:
    api_key: str
    api_url: str
    trusted_cert: bool
    ca_path: str | None
    project_id: int
    slot_name: str
    profile_id: int


def pytest_addoption(parser: Any) -> None:
    parser.addoption("--executable", type=str, action="store")
    parser.addoption("--server", action="append", default=[])


@pytest.fixture(scope="session")
def executable(request: Any) -> str:
    path = request.config.getoption("--executable")

    if path is None:
        pytest.exit("--executable is required")

    assert isinstance(path, str)

    if not os.path.exists(path):
        pytest.exit(f"Executable cannot be found: {path}")

    return path


def parse_config(config_dict: Mapping[str, Any], path: str) -> Server:
    try:
        return Server(
            api_key=config_dict["api_key"],
            api_url=config_dict["api_url"],
            trusted_cert=config_dict["trusted_cert"],
            ca_path=config_dict.get("ca_path"),
            profile_id=config_dict["profile_id"],
            project_id=config_dict["project_id"],
            slot_name=config_dict["slot_name"],
        )
    except KeyError as error:
        (key,) = error.args
        pytest.exit(f"Missing `{key}` in server at {path}")


@functools.cache
def load_config(path: str) -> Server:
    try:
        with open(path, "rb") as toml:
            config_dict = tomllib.load(toml)
    except IOError as error:
        pytest.exit(str(error))
    except tomllib.TOMLDecodeError as error:
        pytest.exit(str(error))

    return parse_config(config_dict, path=path)


def pytest_generate_tests(metafunc: Any) -> None:
    configs = metafunc.config.getoption("--server")

    if "server" in metafunc.fixturenames:
        metafunc.parametrize("server", configs, indirect=True)


@pytest.fixture(scope="session")
def server(request: Any) -> Server:
    return load_config(request.param)
