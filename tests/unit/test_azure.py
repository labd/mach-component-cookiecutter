"""AWS specific tests"""
import pytest
import os
from tests.utils import load_hcl


@pytest.mark.parametrize(
    "language, linux_fx_version", (("node", "NODE|10.15"), ("python", "PYTHON|3.8"))
)
def test_lambda(cookies, language, linux_fx_version):
    result = cookies.bake(template="azure", extra_context={"language": language})

    assert result.project.isdir()
    lambda_path = os.path.join(result.project, "terraform", "functionapp.tf")
    assert os.path.exists(lambda_path)

    result = load_hcl(lambda_path)
    lambda_config = result.resource.azurerm_function_app.main2
    assert result.locals.environment_variables["FUNCTIONS_WORKER_RUNTIME"] == language
    lambda_config.site_config.linux_fx_version == linux_fx_version
