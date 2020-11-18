"""AWS specific tests"""
import pytest
import os
from tests.utils import tf_attribute


@pytest.mark.parametrize(
    "language, linux_fx_version", (("node", "NODE|10.15"), ("python", "PYTHON|3.8"))
)
def test_lambda(cookies, language, linux_fx_version):
    result = cookies.bake(template="azure", extra_context={"language": language})

    assert result.project.isdir()
    lambda_path = os.path.join(result.project, "terraform", "functionapp.tf")
    assert os.path.exists(lambda_path)

    assert tf_attribute(lambda_path, "FUNCTIONS_WORKER_RUNTIME") == language
    assert tf_attribute(lambda_path, "linux_fx_version") == linux_fx_version
