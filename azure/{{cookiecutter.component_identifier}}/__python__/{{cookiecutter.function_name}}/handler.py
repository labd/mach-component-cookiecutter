from azure import functions as func
from sentry_sdk.integrations.flask import FlaskIntegration
from shared.sentry import init_sentry
from .rest import application


# This signature is type checked by Azure, so don't mess with it.
def main(req: func.HttpRequest, context: func.Context) -> func.HttpResponse:
    if req.url.strip("/").endswith("healthchecks"):
        enable_tracing = False
    else:
        enable_tracing = True

    init_sentry(
        enable_tracing=enable_tracing,
        extra_integrations=[FlaskIntegration()],
    )

    return func.WsgiMiddleware(application).main(req, context)
