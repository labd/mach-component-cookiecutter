import os

import pytest
from flask.testing import FlaskClient
from werkzeug.datastructures import Headers


class ApiTestClient(FlaskClient):
    """Set frontdoor header since it's validated every request."""

    def open(self, *args, **kwargs):
        frontdoor_headers = Headers({"X-Azure-FDID": os.environ.get("FRONTDOOR_ID")})
        headers = kwargs.pop("headers", Headers())
        headers.extend(frontdoor_headers)
        kwargs["headers"] = headers
        return super().open(*args, **kwargs)


@pytest.fixture
def app(functionapp_env):
    """Needed by pytest-flask."""
    from {{ cookiecutter.function_name }}.rest import api

    api.app.test_client_class = ApiTestClient

    return api.app
