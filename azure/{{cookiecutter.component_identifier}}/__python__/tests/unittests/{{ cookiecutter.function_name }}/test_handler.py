from flask import url_for


def test_healthcheck(client):
    response = client.get(url_for("healthchecks"))
    assert response.status_code == 200, response.json


def test_some_endpoint(client, mocker):
    order_number = "RR0000012"
    response = client.post(
        url_for("some_endpoint"),
        json={
            "order_number": order_number,
            "message": "Test message",
        },
    )

    assert response.status_code == 200, response.json
