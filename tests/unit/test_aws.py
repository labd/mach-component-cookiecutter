"""AWS specific tests"""
import pytest
import os
from tests.utils import load_hcl


@pytest.mark.parametrize(
    "language, runtime", (("node", "nodejs12.x"), ("python", "python3.8"))
)
def test_runtime(cookies, language, runtime):
    result = cookies.bake(template="aws", extra_context={"language": language})

    assert result.project.isdir()
    lambda_path = os.path.join(result.project, "terraform", "lambda.tf")
    assert os.path.exists(lambda_path)

    result = load_hcl(lambda_path)

    lambda_config = result.module.lambda_function
    assert lambda_config.runtime == runtime
