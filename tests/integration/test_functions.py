import pytest
import subprocess
import os
from typing import List, Tuple
import pytest


def test_run_aws_node(project):
    cwd = project.create("aws", {"language": "node", "name": "unit-test"})
    subprocess.run(["yarn", "install"], cwd=cwd, check=True)
    subprocess.run(["yarn", "test"], cwd=cwd, check=True)


def test_run_azure_python(project, monkeypatch):
    cwd = project.create("azure", {"language": "python", "name": "unit-test"})

    subprocess.run(["python", "-m", "venv", ".env"], cwd=cwd, check=True)
    for k, v in source(os.path.join(cwd, ".env/bin/activate")):
        monkeypatch.setenv(k, v)
    subprocess.run(["pip-compile"], cwd=cwd, check=True, stdout=subprocess.PIPE)
    subprocess.run(["make", "install"], cwd=cwd, check=True, stdout=subprocess.PIPE)
    result = subprocess.run(
        ["pytest", "tests", "--tb=no"], cwd=cwd, stdout=subprocess.PIPE
    )
    assert result.returncode == 0, "\n".join(
        [
            line
            for line in result.stdout.decode().splitlines()
            if line.startswith("FAILED")
        ]
    )


def source(script, update=False) -> List[Tuple[str, str]]:
    pipe = subprocess.Popen(". %s; env" % script, stdout=subprocess.PIPE, shell=True)
    data = pipe.communicate()[0].decode()
    return (line.split("=", 1) for line in data.splitlines())
