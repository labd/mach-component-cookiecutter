import pytest
from fastapi.testclient import TestClient


class ApiTestClient(TestClient):
    pass
    # """Set frontdoor header since it's validated every request."""

    # def open(self, *args, **kwargs):
    #     frontdoor_headers = Headers({"X-Azure-FDID": os.environ.get("FRONTDOOR_ID")})
    #     headers = kwargs.pop("headers", Headers())
    #     headers.extend(frontdoor_headers)
    #     kwargs["headers"] = headers
    #     return super().open(*args, **kwargs)


@pytest.fixture
def client(functionapp_env):
    """Needed by pytest-flask."""
    from api.rest import app

    return ApiTestClient(app)
