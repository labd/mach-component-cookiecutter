import logging

from commercetools import Client
from commercetools.platform.models import OrderCreatedMessage, Order
from commercetools.exceptions import CommercetoolsError


from .base import MessageReceiver
from .exceptions import NotificationException

logger = logging.getLogger(__name__)


class OrderCreatedReceiver(MessageReceiver):
    message_model = OrderCreatedMessage

    def handle(self, message: OrderCreatedMessage):
        if not message.resource or not message.resource.id:
            raise NotificationException("No 'resource' attribute found in message")

        order = get_order(message.resource.id)

        # Implement handler here
        print(order)


def get_order(order_id: str) -> Order:
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
