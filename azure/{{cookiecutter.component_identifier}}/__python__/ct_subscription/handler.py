from azure import functions as func
from typing import Dict
import logging
from .exceptions import NotificationException
from . import receivers
from shared.sentry import init_sentry
import json

logger = logging.getLogger(__name__)


RECEIVERS = {"OrderCreated": receivers.OrderCreatedReceiver}


def main(req: func.HttpRequest, context: func.Context) -> func.HttpResponse:
    try:
        if req.url.strip("/").endswith("healthchecks"):
            enable_tracing = False
        else:
            enable_tracing = True

        init_sentry(enable_tracing=enable_tracing)

        if req.method == "OPTIONS":
            return func.HttpResponse(
                status_code=200,
                headers={"Webhook-Allowed-Origin": "eventgrid.azure.net"},
            )

        try:
            event = req.get_json()
        except ValueError as e:
            return func.HttpResponse(
                json.dumps({"error": str(e)}),
                mimetype="application/json",
                status_code=500,
            )

        logger.info("Python EventGrid trigger got: %s", event)

        try:
            handle(event)
        except NotificationException as e:
            return func.HttpResponse(
                json.dumps({"error": str(e)}),
                mimetype="application/json",
                status_code=500,
            )

        return func.HttpResponse(status_code=200)
    except Exception as e:  # NOQA
        logger.exception("Uncaught exception %s in subscription", e)
        raise


def handle(event: Dict):
    event_data = event["data"]
    if _skip_event(event_data):
        return {"status": "skipped"}

    notification_type = event_data["notificationType"]

    if not notification_type == "Message":
        logger.info("No handler for notification type %s", notification_type)
        return {"status": "skipped"}

    message_type = event_data["type"]

    try:
        receiver_cls = RECEIVERS[message_type]
    except KeyError:
        logger.info("No handler for message type %s", message_type)
        return {"status": "skipped"}

    return receiver_cls().receive(event_data)


def _skip_event(event_data: Dict) -> bool:
    # Initially created subscription generates a one time message for 'confirmation'.
    if event_data["resource"]["typeId"] == "subscription":
        return True

    return False
