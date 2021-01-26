import json
from unittest.mock import Mock

from azure import functions as func

from ct_api_extension.handler import main
from tests.fixtures import get_order_create_data


def test_order_create_sets_order_number(commercetools_api):
    event_data = get_order_create_data()
    body = json.dumps(event_data).encode("UTF-8")
    azure_request = func.HttpRequest(
        method="POST", body=body, url="http://localhost/ct_api_extension"
    )
    mock_context = Mock()

    for i in range(1, 3):
        response = main(azure_request, mock_context)
        response_body = json.loads(response.get_body())

        assert response_body["responseType"] == "UpdateRequest"
        assert len(response_body["actions"]) == 1
        action = response_body["actions"][0]
        assert action["action"] == "setOrderNumber"
        assert action["orderNumber"] == f"unittest-100000{i}"
