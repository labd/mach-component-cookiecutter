from commercetools import types
from commercetools._schemas._message import MessageSchema
from commercetools._schemas._order import OrderReferenceSchema
from marshmallow.exceptions import ValidationError
from typing import Dict, Any
from .exceptions import NotificationException


class MessageReceiver:
    """Base class for any message receiver implementation."""

    message_schema = MessageSchema

    def receive(self, data: Dict):
        try:
            message_obj = self.message_schema().load(data)
        except ValidationError as e:
            raise NotificationException(f"Could not parse message: {e}") from e

        return self.handle(message_obj)

    def handle(self, message_obj: types.Message) -> Any:
        raise NotImplementedError()
