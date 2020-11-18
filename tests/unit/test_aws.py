"""AWS specific tests"""
import pytest
import os
from tests.utils import tf_attribute


@pytest.mark.parametrize(
    "language, runtime", (("node", "nodejs12.x"), ("python", "python3.8"))
)
def test_lambda(cookies, language, runtime):
    result = cookies.bake(template="aws", extra_context={"language": language})

    assert result.project.isdir()
    lambda_path = os.path.join(result.project, "terraform", "lambda.tf")
    assert os.path.exists(lambda_path)

    assert tf_attribute(lambda_path, "runtime") == runtime
