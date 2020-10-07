import pytest
from commercetools.testing import backend_mocker

pytest_plugins = "tests.fixtures"


@pytest.fixture()
def commercetools_api(functionapp_env):
    """
    Intercept any HTTP requests.

    This uses requests mocker, so be careful with mocking other endpoints.
    """
    with backend_mocker() as m:
        yield m


@pytest.fixture(autouse=True)
def functionapp_env(monkeypatch):
    """
    Setup to mimic function app environment
    """
    monkeypatch.setenv("SITE", "nl-unittest")
    monkeypatch.setenv("CTP_PROJECT_KEY", "nl-unittest")
    monkeypatch.setenv("CTP_CLIENT_ID", "foo")
    monkeypatch.setenv("CTP_CLIENT_SECRET", "foo")
    monkeypatch.setenv("CTP_SCOPES", "foo")
    monkeypatch.setenv("CTP_API_URL", "https://localhost")
    monkeypatch.setenv("CTP_AUTH_URL", "https://localhost")
    monkeypatch.setenv("ORDER_PREFIX", "unittest-")
