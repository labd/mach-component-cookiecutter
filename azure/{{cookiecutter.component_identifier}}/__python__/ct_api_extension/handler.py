import json
import logging
from typing import Dict
from urllib.parse import urlparse

from azure import functions as func
from commercetools import types
from commercetools._schemas._extension import ExtensionInputSchema

from . import exceptions, order_handler

logger = logging.getLogger(__name__)


# This signature is type checked by Azure, so don't mess with it.
def main(req: func.HttpRequest, context: func.Context) -> func.HttpResponse:
    parsed = urlparse(req.url)
    if parsed.path.endswith("/healthchecks"):
        return func.HttpResponse(
            status_code=200,
            body=json.dumps({"status": True}),
            mimetype="application/json",
        )

    logger.debug("Got API Extension request: %s", req.__dict__)

    try:
        event = req.get_json()
    except ValueError:
        event = None

    try:
        lambda_response = handle_event(event)
    except exceptions.ProcessError:
        return func.HttpResponse(
            status_code=500, body=json.dumps({}), mimetype="application/json"
        )

    logger.debug("API Extension response: %s", lambda_response)

    return func.HttpResponse(
        status_code=200, body=json.dumps(lambda_response), mimetype="application/json"
    )


def handle_event(event: Dict) -> Dict:
    if not event:
        logger.warning("No data received")
        return {}

    resource_type = event.get("resource", {}).get("typeId")

    if resource_type != types.ExtensionResourceTypeId.ORDER.value:  # noqa: E721
        logger.warning("Resourced unknown resource type: %s", resource_type)
        # silently fail so the action will still work
        return {}

    ext_input: types.ExtensionInput = ExtensionInputSchema().load(event)
    return order_handler.handle(ext_input)
