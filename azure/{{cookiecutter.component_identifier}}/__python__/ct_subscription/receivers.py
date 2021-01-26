import logging
import requests
import os

from commercetools import Client, types
from commercetools._schemas._message import OrderCreatedMessageSchema
from commercetools.exceptions import CommercetoolsError


from .base import MessageReceiver
from .exceptions import NotificationException

logger = logging.getLogger(__name__)


class OrderCreatedReceiver(MessageReceiver):
    message_schema = OrderCreatedMessageSchema

    def handle(self, message: types.OrderCreatedMessage):
        if not message.resource or not message.resource.id:
            raise NotificationException("No 'resource' attribute found in message")

        order = get_order(message.resource.id)

        # Implement handler here
        print(order)


def get_order(order_id: str) -> types.Order:
    """Get the latest version of the Order."""
    client = Client()

    try:
        return client.orders.get_by_id(
            order_id,
            expand=[
                "paymentInfo.payments[*]",
                "lineItems[*].productType",
                "discountCodes[*].discountCode",
            ],
        )
    except (EnvironmentError, CommercetoolsError) as e:
        raise NotificationException(f"Could not fetch order: {e}") from e
