from typing import Dict

from ct_subscription import handler


def get_notification_message(notification_type: str) -> Dict:
    return {
        "id": "3dff1253-daf2-4123-8db1-ffbc76fa9733-c1",
        "source": "/nl-unittests-dev/orders",
        "specversion": "1.0",
        "type": f"com.commercetools.order.change.{notification_type}",
        "subject": "3dff1253-daf2-4123-8db1-ffbc76fa9733",
        "time": "2020-05-28T10:01:34.786Z",
        "data": {
            "notificationType": notification_type,
            "projectKey": "nl-unittests-dev",
            "resource": {
                "typeId": "order",
                "id": "1edd1253-daf2-4123-8db1-ffbc76fa9799-b4",
            },
            "resourceUserProvidedIdentifiers": {"orderNumber": "12345"},
            "version": 1,
            "modifiedAt": "2020-05-28T10:01:34.786Z",
        },
    }


def get_subscription_message(
    action_type: str = "OrderPaymentStateChanged",
) -> Dict:
    return {
        "id": "32ceddb2-3899-4115-9315-0be73d7d86cd",
        "source": "/nl-unittests-dev/orders",
        "specversion": "1.0",
        "type": f"com.commercetools.order.message.{action_type}",
        "subject": "36a66613-90cf-4456-9ec7-17df396d8aaa",
        "time": "2020-06-08T11:00:45.943Z",
        "dataref": "/nl-unittests-dev/messages/32ceddb2-3899-4115-9315-0be73d7d86cd",
        "sequence": "2",
        "sequencetype": "Integer",
        "data": {
            "notificationType": "Message",
            "projectKey": "nl-unittests-dev",
            "id": "32ceddb2-3899-4115-9315-0be73d7d86cd",
            "version": 1,
            "sequenceNumber": 2,
            "resource": {
                "typeId": "order",
                "id": "36a66613-90cf-4456-9ec7-17df396d8aaa",
            },
            "resourceVersion": 3,
            "resourceUserProvidedIdentifiers": {"orderNumber": "12345"},
            "type": action_type,
            "createdAt": "2020-06-08T11:00:45.943Z",
            "lastModifiedAt": "2020-06-08T11:00:45.943Z",
        },
    }


def test_notification_no_handler():
    notification = get_notification_message("ResourceUpdated")
    assert handler.handle(notification) == {"status": "skipped"}


def test_message_no_handler():
    message = get_subscription_message()
    assert handler.handle(message) == {"status": "skipped"}


def test_message_notifications_are_handled(mocker):
    action_type = "OrderCreated"
    message = get_subscription_message(action_type)
    mock = mocker.patch("ct_subscription.receivers.MessageReceiver.receive")

    handler.handle(message)
    assert mock.call_count == 1
