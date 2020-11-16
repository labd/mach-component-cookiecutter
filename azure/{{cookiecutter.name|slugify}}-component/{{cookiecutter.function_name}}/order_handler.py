import logging
import os
from typing import Dict, List

from commercetools import CommercetoolsError, client, types
from commercetools._schemas._order import OrderUpdateSchema

from .exceptions import ProcessError, UnsupportedAction

logger = logging.getLogger(__name__)


def handle(order_input: types.ExtensionInput) -> Dict:
    """Processes an extension input for an Order action."""
    if order_input.action != types.ExtensionAction.CREATE:
        raise UnsupportedAction()

    order = order_input.resource.obj
    if not order:
        raise ProcessError("Missing order on order reference.")

    actions: List[types.OrderUpdateAction] = []

    if not order.order_number:
        order_number = generate_order_number(order)
        actions.append(types.OrderSetOrderNumberAction(order_number=order_number))

    update_obj = types.OrderUpdate(version=0, actions=actions)
    update_dump = OrderUpdateSchema().dump(update_obj)

    return {"responseType": "UpdateRequest", "actions": update_dump["actions"]}


def generate_order_number(order: types.Order) -> str:
    prefix = os.environ.get("ORDER_PREFIX", "")
    return f"{prefix}{get_order_number_suffix(order)}"


def get_order_number_suffix(order: types.Order) -> str:
    """Return an unique order number using CommerceTools custom objects.

    We use a custom object to store the current value and increment it for
    every call. If a conflict occurs (race condition) then we retry it with
    a max of 20 times. (this number is randomly chosen).
    """
    container = "order-numbers"
    key = "order-number"

    ct_client = client.Client()

    max_tries = 20
    for i in range(max_tries):
        # Retrieve latest order number
        try:
            logger.debug("Retrieving latest order number")
            obj = ct_client.custom_objects.get_by_container_and_key(
                container=container, key=key
            )
            current_version = obj.version
            current_value = obj.value
        except (CommercetoolsError, EnvironmentError):
            current_value = 1_000_000
            current_version = None

        # Increase order number and retry on conflict
        try:
            logger.debug("Increasing order number")
            response = ct_client.custom_objects.create_or_update(
                types.CustomObjectDraft(
                    container=container,
                    key=key,
                    value=current_value + 1,
                    version=current_version,
                )
            )

            order_number = str(response.value)
            logger.debug("Return order number: %s", order_number)
            return order_number
        except CommercetoolsError as e:
            if e.response.status_code == 409:
                logger.warning("Conflict on order number generator")
                continue
            else:
                raise

    raise ProcessError(f"Could not get order number in {max_tries} tries")
