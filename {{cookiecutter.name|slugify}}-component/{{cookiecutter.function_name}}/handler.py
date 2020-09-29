import json
import logging
from urllib.parse import urlparse

from azure import functions as func

logger = logging.getLogger()

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
    event = req.get_json()
    response_data = handle_event(event)
    logger.debug("API Extension response: %s", response_data)
    return func.HttpResponse(
        status_code=200, body=json.dumps(response_data), mimetype="application/json"
    )

def handle_event(event):
    return {
        "status": "ok"
    }
